package com.example.local_image_provider

import android.app.Activity
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.json.JSONObject

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
    } else {
      result.notImplemented()
    }
  }

    fun getLatestImages( result: Result ) {
        val images = ArrayList<String>()
        val imgUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val mediaColumns = arrayOf( MediaStore.Images.ImageColumns.DISPLAY_NAME,
                MediaStore.Images.ImageColumns.DATE_TAKEN,
                MediaStore.Images.ImageColumns.TITLE,
                MediaStore.Images.ImageColumns.HEIGHT,
                MediaStore.Images.ImageColumns.WIDTH,
                MediaStore.Images.ImageColumns.BUCKET_ID)
        val mediaResolver = pluginActivity.contentResolver
        val imageCursor = mediaResolver.query( imgUri, mediaColumns, null, null, null )
        if ( null != imageCursor ) {
            val widthColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.WIDTH)
            val heightColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.HEIGHT)
            val dateColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.DATE_TAKEN)
            val titleColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.TITLE)
            val idColumn = imageCursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.BUCKET_ID)
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
        result.success( images )
    }
}
