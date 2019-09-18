package com.example.local_image_provider

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageDecoder
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import com.bumptech.glide.Glide
import com.bumptech.glide.GlideBuilder
import com.bumptech.glide.annotation.GlideModule
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.module.AppGlideModule
import com.bumptech.glide.request.RequestOptions
import com.bumptech.glide.signature.ObjectKey
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.util.concurrent.Future

class LocalImageProviderPlugin ( activity: Activity): MethodCallHandler {
    val pluginActivity: Activity

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
      getLatestImages( result )
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

    fun getLatestImages( result: Result ) {
        Thread(Runnable {
            val images = ArrayList<String>()
            val imgUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            val mediaColumns = arrayOf( MediaStore.Images.ImageColumns.DISPLAY_NAME,
                    MediaStore.Images.ImageColumns.DATE_TAKEN,
                    MediaStore.Images.ImageColumns.TITLE,
                    MediaStore.Images.ImageColumns.HEIGHT,
                    MediaStore.Images.ImageColumns.WIDTH,
                    MediaStore.MediaColumns._ID)
            val mediaResolver = pluginActivity.contentResolver
            val imageCursor = mediaResolver.query( imgUri, mediaColumns, null, null, null )
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
                    imgJson.put( "creationDate", imageCursor.getString(dateColumn))
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
