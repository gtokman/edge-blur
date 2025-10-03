//
//  CIKernelCache.swift
//  AemiSDR
//
// Created by Guillaume Coquard on 20.09.25.
//

import CoreImage
import OSLog

/**
 * CIKernelCache serves as the base class for managing and caching Core Image Metal kernels.
 *
 * This class provides the foundational infrastructure for loading Metal-based Core Image kernels
 * from compiled Metal libraries (.metallib files). It handles kernel caching, provides a shared
 * CIContext for image processing operations, and offers utility methods for generating CGImages
 * from kernel operations.
 *
 * Key Features:
 * - Lazy loading of Metal library data from bundle resources
 * - Pre-configured CIContext optimized for DisplayP3 color space
 * - Centralized logging for debugging kernel operations
 * - Static methods for common kernel-to-image conversion tasks
 *
 * Subclasses should extend this class to provide specific kernel implementations
 * (e.g., VariableBlurCache, AlphaMaskCache).
 */
class CIKernelCache {
    // MARK: - Logging
    
    /**
     * Shared logger instance for kernel-related operations.
     *
     * Uses OSLog with a subsystem identifier for the AemiShader framework
     * and dynamically sets the category based on the actual class name.
     * This provides clear, filterable logging for debugging kernel issues.
     */
    static var logger: Logger {
        Logger(subsystem: "studio.aemi.AemiShader", category: "\(Self.self)")
    }
    
    // MARK: - Core Image Context
    
    /**
     * Shared CIContext optimized for high-quality image processing.
     *
     * Configuration details:
     * - **Color Spaces**: Uses DisplayP3 for both working and output color spaces,
     *   providing wide color gamut support for modern displays
     * - **Caching**: Disabled intermediate caching (`cacheIntermediates: false`) to
     *   reduce memory pressure during complex kernel operations
     * - **Priority**: Set to low priority (`priorityRequestLow: true`) to avoid
     *   blocking the main thread during intensive processing
     *
     * This context is reused across all kernel operations for performance efficiency.
     */
    
    static let context: CIContext = {
        let p3 = CGColorSpace(name: CGColorSpace.displayP3)
        let opts: [CIContextOption: Any] = [
            CIContextOption(
                rawValue: CIContextOption.workingColorSpace.rawValue
            ): p3 as Any,
            CIContextOption(
                rawValue: CIContextOption.outputColorSpace.rawValue
            ): p3 as Any,
            CIContextOption(
                rawValue: CIContextOption.cacheIntermediates.rawValue
            ): false as NSNumber,
            CIContextOption(
                rawValue: CIContextOption.priorityRequestLow.rawValue
            ): true as NSNumber
        ]
        return CIContext(
            options: opts as [CIContextOption : Any]
        )
    }()
    // Helper to resolve resource bundle in both SwiftPM and CocoaPods environments
    private enum ResourceBundle {
        final class Marker {}
        static let bundle: Bundle = {
#if SWIFT_PACKAGE
            return Bundle.module
#else
            let candidates: [URL?] = [
                Bundle(for: Marker.self).resourceURL,
                Bundle.main.resourceURL
            ]
            for candidate in candidates {
                if let url = candidate?.appendingPathComponent("edge-blur.bundle"),
                   let b = Bundle(url: url) {
                    return b
                }
            }
            return Bundle(for: Marker.self)
#endif
        }()
    }
    
    // MARK: - Metal Library Loading
    
    /**
     * Lazily loaded Metal library data containing compiled shader functions.
     *
     * Attempts to load the "default.metallib" file from the main bundle, which should
     * contain all compiled Metal shaders for the application. The library is loaded
     * once and cached for subsequent kernel creation operations.
     *
     * **Important**: This expects a Metal library named "default.metallib" to be
     * present in the app bundle. If the library is missing or corrupted, all kernel
     * creation will fail gracefully with appropriate error logging.
     *
     * - Returns: Data containing the Metal library, or `nil` if loading fails
     */
    static let libraryData: Data? = {
        guard let url = ResourceBundle.bundle.url(forResource: "AemiSDR", withExtension: "metallib") else {
            logger.error("Failed to locate metallib in bundle.")
            return nil
        }
        
        do {
            return try Data(contentsOf: url)
        } catch {
            logger.error("Failed to load metallib data: \(error.localizedDescription)")
            return nil
        }
    }()
    
    // MARK: - Utility Methods
    
    /**
     * Generates a CGImage from a CIColorKernel using specified parameters.
     *
     * This is a convenience method that handles the complete pipeline from kernel
     * application to final CGImage generation. It provides comprehensive error
     * handling and logging for each step of the process.
     *
     * **Process Flow**:
     * 1. Validates the kernel is not nil
     * 2. Applies the kernel with the provided extent and arguments
     * 3. Renders the resulting CIImage to a CGImage using the shared context
     * 4. Returns the final CGImage or nil if any step fails
     *
     * - Parameters:
     *   - kernel: The CIColorKernel to apply (must not be nil)
     *   - extent: The rectangular region to process in pixels
     *   - arguments: Array of arguments to pass to the kernel function
     * - Returns: Generated CGImage, or nil if the operation fails
     *
     * **Usage Example**:
     * ```swift
     * let cgImage = CIKernelCache.generateCGImage(
     *     kernel: someKernel,
     *     extent: CGRect(x: 0, y: 0, width: 100, height: 100),
     *     arguments: [width, height, cornerRadius]
     * )
     * ```
     */
    static func generateCGImage(kernel: CIColorKernel?, extent: CGRect, arguments: [Any]) -> CGImage? {
        guard let kernel else {
            logger.error("Kernel is nil.")
            return nil
        }
        
        guard let image = kernel.apply(extent: extent, arguments: arguments) else {
            logger.error("Kernel application failed.")
            return nil
        }
        
        guard let cgImage = context.createCGImage(image, from: extent) else {
            logger.error("CGImage creation failed.")
            return nil
        }
        
        return cgImage
    }
}

// MARK: - Kernel Extensions

/**
 * Extension containing specific kernel implementations.
 *
 * This extension demonstrates how subclasses or extensions can add specific
 * kernel implementations. Each kernel follows the same pattern:
 * 1. Check for library data availability
 * 2. Attempt to create the kernel from the Metal library
 * 3. Log errors and return nil on failure
 * 4. Cache the result for subsequent use
 */
extension CIKernelCache {
    /**
     * Linear gradient mask kernel for directional blur effects.
     *
     * Creates a CIColorKernel that generates linear gradient masks, useful for
     * creating fade-in/fade-out blur effects or directional edge softening.
     *
     * **Metal Function**: `linearMask` from the compiled Metal library
     * **Expected Signature**:
     * ```metal
     * float4 linearMask(float widthPx, float heightPx, float startOffset, float inverted, coreimage::destination dest)
     * ```
     *
     * **Parameters for kernel.apply()**:
     * - widthPx: Width of the gradient in pixels
     * - heightPx: Height of the gradient in pixels
     * - startOffset: Start position as fraction of height (0.0 to 1.0)
     * - inverted: 0 for top-to-bottom, 1 for bottom-to-top
     *
     * - Returns: Cached CIColorKernel instance, or nil if creation fails
     */
    static let linearMask: CIColorKernel? = {
        guard let libraryData else {
            logger.error("Library data is nil.")
            return nil
        }
        
        do {
            return try CIColorKernel(functionName: "linearMask", fromMetalLibraryData: libraryData)
        } catch {
            logger.error("Failed to create linearMask kernel: \(error.localizedDescription)")
            return nil
        }
    }()
}
