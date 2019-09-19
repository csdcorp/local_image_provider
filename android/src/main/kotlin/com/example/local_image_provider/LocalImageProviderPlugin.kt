package com.example.local_image_provider

import android.app.Activity
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.text.SimpleDateFormat
import java.util.*
import kotlin.collections.ArrayList

class LocalImageProviderPlugin ( activity: Activity): MethodCallHandler {
    val pluginActivity: Activity
    val isoFormatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SZZZZZ")

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "local_image_provider")
      channel.setMethodCallHandler(LocalImageProviderPlugin( registrar.activity()))
    }
  }

    init {
        pluginActivity = activity
    }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "latest_images") {
        val maxResults = call.arguments as Integer
        if ( null != maxResults ) {
            getLatestImages( maxResults, result )
        }
        else {
            result.error( "Missing parameters, requires maxPhotos", null, null )
        }
    }
    else if ( call.method == "image_bytes") {
        val id = call.argument<String>( "id")
        val width = call.argument<Int>("pixelWidth")
        val height = call.argument<Int>("pixelHeight")
        if (id != null && width != null && height != null ) {
            getImageBytes( id, width, height, result )
        }
        else {
            result.error( "Missing parameters, requires id, width, height", null, null )
        }
    }
    else {
      result.notImplemented()
    }
  }

    fun getLatestImages( maxResults: Integer, result: Result ) {
        Thread(Runnable {
            val images = ArrayList<String>()
            val imgUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            val mediaColumns = arrayOf( MediaStore.Images.ImageColumns.DISPLAY_NAME,
                    MediaStore.Images.ImageColumns.DATE_TAKEN,
                    MediaStore.Images.ImageColumns.TITLE,
                    MediaStore.Images.ImageColumns.HEIGHT,
                    MediaStore.Images.ImageColumns.WIDTH,
                    MediaStore.MediaColumns._ID)
            val sortOrder = "${MediaStore.Images.ImageColumns.DATE_TAKEN} DESC LIMIT $maxResults"
            val mediaResolver = pluginActivity.contentResolver
            val imageCursor = mediaResolver.query( imgUri, mediaColumns, null,
                    null, sortOrder )
            imageCursor?.use {
                val widthColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.WIDTH)
                val heightColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.HEIGHT)
                val dateColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.DATE_TAKEN)
                val titleColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.TITLE)
                val idColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns._ID)
                while ( imageCursor.moveToNext()) {
                    val imgJson = JSONObject()
                    imgJson.put( "title", imageCursor.getString(titleColumn))
                    imgJson.put( "pixelWidth", imageCursor.getInt(widthColumn))
                    imgJson.put( "pixelHeight", imageCursor.getInt(heightColumn))
                    imgJson.put( "id", imageCursor.getString(idColumn))
                    val takenOn = Date( imageCursor.getLong(dateColumn))
                    val isoDate = isoFormatter.format( takenOn )
                    imgJson.put( "creationDate", isoDate )
                    images.add( imgJson.toString())
                }
            }
            pluginActivity.runOnUiThread( Runnable {result.success( images )})
        }).start()
    }

    fun getImageBytes( id: String, width: Int, height: Int, result: Result ) {
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
                pluginActivity.runOnUiThread(Runnable { result.success(jpegBytes.toByteArray()) })
            }
        }).start()
    }
}
