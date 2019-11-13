package com.example.local_image_provider

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.ContentResolver
import android.content.pm.PackageManager
import android.os.Build
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.text.SimpleDateFormat
import java.util.*
import kotlin.collections.ArrayList


enum class LocalImageProviderErrors {
    imgLoadFailed,
    imgNotFound,
    missingOrInvalidArg,
    multipleRequests,
    unimplemented
}

class LocalImageProviderPlugin(activity: Activity) : MethodCallHandler,
        PluginRegistry.RequestPermissionsResultListener {
    private val pluginActivity: Activity = activity
    private val application: Application = activity.application
    private val isoFormatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SZZZZZ")
    private val minSdkForImageSupport = 8
    private val imagePermissionCode = 34264
    private var activeResult: Result? = null
    private var initializedSuccessfully: Boolean = false
    private var permissionGranted: Boolean = false
    private val imageColums = arrayOf(MediaStore.Images.ImageColumns.DISPLAY_NAME,
        MediaStore.Images.ImageColumns.DATE_TAKEN,
        MediaStore.Images.ImageColumns.TITLE,
        MediaStore.Images.ImageColumns.HEIGHT,
        MediaStore.Images.ImageColumns.WIDTH,
        MediaStore.MediaColumns._ID)

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "plugin.csdcorp.com/local_image_provider")
            val imagePlugin = LocalImageProviderPlugin(registrar.activity())
            registrar.addRequestPermissionsResultListener(imagePlugin)
            channel.setMethodCallHandler(imagePlugin)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> initialize(result)
            "has_permission" -> hasPermission(result)
            "latest_images" -> {
                if (null != call.arguments && call.arguments is Int) {
                    val maxResults = call.arguments as Int
                    getLatestImages(maxResults, result)
                } else {
                    result.error(LocalImageProviderErrors.missingOrInvalidArg.name,
                            "Missing arg maxPhotos", null)
                }
            }
            "albums" -> {
                if (null != call.arguments && call.arguments is Int) {
                    val localAlbumType = call.arguments as Int
                    getAlbums(localAlbumType, result)
                } else {
                    result.error(LocalImageProviderErrors.missingOrInvalidArg.name,
                            "Missing arg albumType", null)
                }
            }
            "image_bytes" -> {
                val id = call.argument<String>("id")
                val width = call.argument<Int>("pixelWidth")
                val height = call.argument<Int>("pixelHeight")
                if (id != null && width != null && height != null) {
                    getImageBytes(id, width, height, result)
                } else {
                    result.error(LocalImageProviderErrors.missingOrInvalidArg.name,
                            "Missing arg requires id, width, height", null)
                }
            }
            "images_in_album" -> {
                val albumId = call.argument<String>("albumId")
                val maxImages = call.argument<Int>("maxImages")
                if (albumId != null && maxImages != null) {
                    findImagesInAlbum(albumId, maxImages, result)
                } else {
                    result.error(LocalImageProviderErrors.missingOrInvalidArg.name,
                            "Missing arg requires albumId, maxImages", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun hasPermission(result: Result) {
        if (sdkVersionTooLow(result)) {
            return
        }
        result.success(ContextCompat.checkSelfPermission(application,
                Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED )
    }

    private fun initialize(result: Result) {
        if (sdkVersionTooLow(result)) {
            return
        }
        if (null != activeResult) {
            result.error(LocalImageProviderErrors.multipleRequests.name,
                    "Only one initialize at a time", null)
            return
        }
        activeResult = result
        initializeIfPermitted(application)
    }

    private fun sdkVersionTooLow(result: Result): Boolean {
        if (Build.VERSION.SDK_INT < minSdkForImageSupport) {
            result.success(false)
            return true
        }
        return false
    }

    private fun isNotInitialized(result: Result): Boolean {
        if (!initializedSuccessfully) {
            result.success(false)
        }
        return !initializedSuccessfully
    }


    private fun getAlbums(localAlbumType: Int, result: Result) {
        if (isNotInitialized(result)) {
            return
        }
        val albums = ArrayList<String>()
        Thread(Runnable {
            albums.addAll(getAlbumsFromLocation(MediaStore.Images.Media.INTERNAL_CONTENT_URI))
            albums.addAll(getAlbumsFromLocation(MediaStore.Images.Media.EXTERNAL_CONTENT_URI))
            pluginActivity.runOnUiThread { result.success(albums) }
        }).start()

    }

    private fun getAlbumsFromLocation(imgUri: Uri): ArrayList<String> {
        val mediaColumns = arrayOf(
                "DISTINCT " + MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME,
                MediaStore.Images.ImageColumns.BUCKET_ID
        )
        val sortOrder = "${MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME} ASC"
        val mediaResolver = pluginActivity.contentResolver
        val albums = ArrayList<String>()
        val imageCursor = mediaResolver.query(imgUri, mediaColumns, null,
                null, sortOrder)
        imageCursor?.use {
            val titleColumn = imageCursor.getColumnIndexOrThrow(
                    MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME)
            val idColumn = imageCursor.getColumnIndexOrThrow(
                    MediaStore.Images.ImageColumns.BUCKET_ID)
            while (imageCursor.moveToNext()) {
                val bucketId = imageCursor.getString(idColumn)
                val imageCount = getAlbumImageCount(bucketId, imgUri )
                val imgJson = JSONObject()
                imgJson.put("title", imageCursor.getString(titleColumn))
                imgJson.put("imageCount", imageCount)
                imgJson.put("id", bucketId)
                imgJson.put("coverImg", getAlbumsCoverImage( bucketId, imgUri ))
                albums.add(imgJson.toString())
            }
        }
        return albums
    }

    private fun getAlbumsCoverImage(bucketId: String, imgUri: Uri): JSONObject {
        var imgJson = JSONObject()
        val mediaColumns = arrayOf(
                MediaStore.Images.ImageColumns._ID,
                MediaStore.Images.ImageColumns.BUCKET_ID,
                MediaStore.Images.ImageColumns.DATE_TAKEN,
                MediaStore.Images.ImageColumns.DISPLAY_NAME,
                MediaStore.Images.ImageColumns.TITLE,
                MediaStore.Images.ImageColumns.HEIGHT,
                MediaStore.Images.ImageColumns.WIDTH
        )
        val sortOrder = "${MediaStore.Images.ImageColumns.DATE_TAKEN} DESC LIMIT 1"
        val selection = "${MediaStore.Images.ImageColumns.BUCKET_ID} = ?"
        val selectionArgs = arrayOf(bucketId)
        val mediaResolver = pluginActivity.contentResolver
        val imageCursor = mediaResolver.query(imgUri, mediaColumns, selection,
                selectionArgs, sortOrder)
        imageCursor?.use {
            val widthColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.WIDTH)
            val heightColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.HEIGHT)
            val dateColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.DATE_TAKEN)
            val titleColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.TITLE)
            val idColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns._ID)
            while (imageCursor.moveToNext()) {
                imgJson = imageToJson(
                        imageCursor.getString(titleColumn),
                        imageCursor.getInt(heightColumn),
                        imageCursor.getInt(widthColumn),
                        imageCursor.getString(idColumn),
                        Date(imageCursor.getLong(dateColumn))
                )
            }
        }
        return imgJson
    }

    private fun getAlbumImageCount(bucketId: String, imgUri: Uri): Int {
        var imageCount = 0
        val mediaColumns = arrayOf(
                MediaStore.Images.ImageColumns._ID,
                MediaStore.Images.ImageColumns.BUCKET_ID
        )
        val selection = "${MediaStore.Images.ImageColumns.BUCKET_ID} = ?"
        val selectionArgs = arrayOf(bucketId)
        val mediaResolver = pluginActivity.contentResolver
        val imageCursor = mediaResolver.query(imgUri, mediaColumns, selection,
                selectionArgs, null)
        imageCursor?.use {
            imageCount = imageCursor.count
        }
        return imageCount
    }

    private fun getLatestImages(maxResults: Int, result: Result) {
        if (isNotInitialized(result)) {
            return
        }
        Thread(Runnable {
            val imgUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            val sortOrder = "${MediaStore.Images.ImageColumns.DATE_TAKEN} DESC LIMIT $maxResults"
            val mediaResolver = pluginActivity.contentResolver
            val images = findImagesToJson(mediaResolver, imgUri, null, null, sortOrder )
            pluginActivity.runOnUiThread { result.success(images) }
        }).start()
    }

    private fun findImagesInAlbum(albumId: String, maxImages: Int, result: Result) {
        if (isNotInitialized(result)) {
            return
        }
        Thread(Runnable {
            val imgUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            val sortOrder = "${MediaStore.Images.ImageColumns.DATE_TAKEN} DESC LIMIT $maxImages"
            val selection = "${MediaStore.Images.ImageColumns.BUCKET_ID} = ?"
            val selectionArgs = arrayOf(albumId)
            val mediaResolver = pluginActivity.contentResolver
            val images = findImagesToJson(mediaResolver, imgUri, selection, selectionArgs, sortOrder )
            pluginActivity.runOnUiThread { result.success(images) }
        }).start()
    }

    private fun findImagesToJson(mediaResolver: ContentResolver, imgUri: Uri, selection: String?,
                                 selectionArgs: Array<String>?, sortOrder: String? ):
            ArrayList<String> {
        val images = ArrayList<String>()
        val imageCursor = mediaResolver.query(imgUri, imageColums, selection,
                selectionArgs, sortOrder)
        imageCursor?.use {
            val widthColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.WIDTH)
            val heightColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.HEIGHT)
            val dateColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.DATE_TAKEN)
            val titleColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.TITLE)
            val idColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns._ID)
            while (imageCursor.moveToNext()) {
                val imgJson = imageToJson(
                        imageCursor.getString(titleColumn),
                        imageCursor.getInt(heightColumn),
                        imageCursor.getInt(widthColumn),
                        imageCursor.getString(idColumn),
                        Date(imageCursor.getLong(dateColumn))
                )
                images.add(imgJson.toString())
            }
        }
        return images
    }

    private fun imageToJson( title: String, height: Int, width: Int, id: String, takenOn: Date ) : JSONObject {
        val imgJson = JSONObject()
        imgJson.put("title", title)
        imgJson.put("pixelWidth", width )
        imgJson.put("pixelHeight",height )
        imgJson.put("id", id )
        val isoDate = isoFormatter.format(takenOn)
        imgJson.put("creationDate", isoDate)
        return imgJson
    }

    private fun getImageBytes(id: String, width: Int, height: Int, result: Result) {
        if (isNotInitialized(result)) {
            return
        }
        Thread(Runnable {
            val imgUri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
            val bitmapLoad = GlideApp.with(pluginActivity)
                    .asBitmap()
                    .load(imgUri)
                    .override(width, height)
                    .fitCenter()
                    .submit()
            val bitmap = bitmapLoad.get()
            val jpegBytes = ByteArrayOutputStream()
            jpegBytes.use {
                bitmap.compress(Bitmap.CompressFormat.JPEG, 70, jpegBytes)
                pluginActivity.runOnUiThread { result.success(jpegBytes.toByteArray()) }
            }
        }).start()
    }

    private fun initializeIfPermitted(context: Application) {
        permissionGranted = ContextCompat.checkSelfPermission(context,
                Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        if (!permissionGranted) {
            ActivityCompat.requestPermissions(pluginActivity,
                    arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE), imagePermissionCode)
        } else {
            completeInitialize()
        }
    }

    private fun completeInitialize() {

        initializedSuccessfully = permissionGranted
        activeResult?.success(permissionGranted)
        activeResult = null
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?,
                                            grantResults: IntArray?): Boolean {
        when (requestCode) {
            imagePermissionCode -> {
                if (null != grantResults) {
                    permissionGranted = grantResults.isNotEmpty() &&
                            grantResults[0] == PackageManager.PERMISSION_GRANTED
                }
                completeInitialize()
                return true
            }
        }
        return false
    }
}
