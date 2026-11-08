package com.antigravity.echo_bloom

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaPlayer
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Binder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import java.io.File

/**
 * Foreground service for media playback notifications in Echo Bloom.
 *
 * Shows a persistent media-style notification with play/pause, skip-next,
 * and skip-previous controls. Integrates with Android MediaSession for
 * lock screen and Bluetooth/headset button support.
 *
 * Communicates back to MainActivity via [MediaActionListener] callbacks.
 */
class MediaPlaybackService : Service() {

    companion object {
        const val CHANNEL_ID = "echo_bloom_playback"
        const val NOTIFICATION_ID = 1001

        const val ACTION_PLAY = "com.antigravity.echo_bloom.ACTION_PLAY"
        const val ACTION_PAUSE = "com.antigravity.echo_bloom.ACTION_PAUSE"
        const val ACTION_NEXT = "com.antigravity.echo_bloom.ACTION_NEXT"
        const val ACTION_PREVIOUS = "com.antigravity.echo_bloom.ACTION_PREVIOUS"
        const val ACTION_STOP = "com.antigravity.echo_bloom.ACTION_STOP"

        var activePlayer: MediaPlayer? = null
        var isPlayerPrepared: Boolean = false
    }

    interface MediaActionListener {
        fun onPlayRequested()
        fun onPauseRequested()
        fun onNextRequested()
        fun onPreviousRequested()
        fun onStopRequested()
    }

    private val binder = LocalBinder()
    var actionListener: MediaActionListener? = null

    private var mediaSession: MediaSession? = null
    private var notificationManager: NotificationManager? = null

    private var currentTitle: String = "Echo Bloom"
    private var currentArtist: String = "Unknown Artist"
    private var currentAlbum: String = ""
    private var currentArtworkPath: String? = null
    private var isPlaying: Boolean = false
    private var currentPositionMs: Long = 0
    private var currentDurationMs: Long = 0

    inner class LocalBinder : Binder() {
        fun getService(): MediaPlaybackService = this@MediaPlaybackService
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
        setupMediaSession()
        startForegroundSafely()
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val artworkCache = mutableMapOf<String, Bitmap>()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundSafely()
        when (intent?.action) {
            ACTION_PLAY -> actionListener?.onPlayRequested()
            ACTION_PAUSE -> actionListener?.onPauseRequested()
            ACTION_NEXT -> actionListener?.onNextRequested()
            ACTION_PREVIOUS -> actionListener?.onPreviousRequested()
            ACTION_STOP -> {
                actionListener?.onStopRequested()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Echo Bloom Playback",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Media playback controls"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun setupMediaSession() {
        mediaSession = MediaSession(this, "EchoBloomSession").apply {
            setCallback(object : MediaSession.Callback() {
                override fun onPlay() {
                    actionListener?.onPlayRequested()
                }

                override fun onPause() {
                    actionListener?.onPauseRequested()
                }

                override fun onSkipToNext() {
                    actionListener?.onNextRequested()
                }

                override fun onSkipToPrevious() {
                    actionListener?.onPreviousRequested()
                }

                override fun onStop() {
                    actionListener?.onStopRequested()
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }

                override fun onSeekTo(pos: Long) {}
            })
            isActive = true
        }
    }

    fun startForegroundSafely() {
        try {
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: Exception) {}
    }

    fun updateMetadata(title: String, artist: String, album: String, artworkPath: String?) {
        currentTitle = title
        currentArtist = artist
        currentAlbum = album
        currentArtworkPath = artworkPath
        updateMediaSessionMetadata()
        showNotification()
    }

    fun updatePlaybackState(playing: Boolean, positionMs: Long, durationMs: Long) {
        isPlaying = playing
        currentPositionMs = positionMs
        currentDurationMs = durationMs
        updateMediaSessionPlaybackState()
        showNotification()
    }

    fun startForegroundNotification() {
        startForegroundSafely()
    }

    fun stopForegroundNotification() {
        mediaSession?.isActive = false
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    private fun updateMediaSessionMetadata() {
        val builder = android.media.MediaMetadata.Builder()
            .putString(android.media.MediaMetadata.METADATA_KEY_TITLE, currentTitle)
            .putString(android.media.MediaMetadata.METADATA_KEY_ARTIST, currentArtist)
            .putString(android.media.MediaMetadata.METADATA_KEY_ALBUM, currentAlbum)
            .putLong(android.media.MediaMetadata.METADATA_KEY_DURATION, currentDurationMs)

        val artwork = loadArtworkBitmap()
        if (artwork != null) {
            builder.putBitmap(android.media.MediaMetadata.METADATA_KEY_ALBUM_ART, artwork)
        }

        mediaSession?.setMetadata(builder.build())
    }

    private fun updateMediaSessionPlaybackState() {
        val stateBuilder = PlaybackState.Builder()
            .setActions(
                PlaybackState.ACTION_PLAY or
                PlaybackState.ACTION_PAUSE or
                PlaybackState.ACTION_SKIP_TO_NEXT or
                PlaybackState.ACTION_SKIP_TO_PREVIOUS or
                PlaybackState.ACTION_STOP or
                PlaybackState.ACTION_SEEK_TO
            )
            .setState(
                if (isPlaying) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED,
                currentPositionMs,
                if (isPlaying) 1.0f else 0.0f
            )
        mediaSession?.setPlaybackState(stateBuilder.build())
    }

    private fun buildNotification(): Notification {
        val contentIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val prevIntent = PendingIntent.getService(
            this, 0,
            Intent(this, MediaPlaybackService::class.java).apply { action = ACTION_PREVIOUS },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val playPauseIntent = PendingIntent.getService(
            this, 1,
            Intent(this, MediaPlaybackService::class.java).apply {
                action = if (isPlaying) ACTION_PAUSE else ACTION_PLAY
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val nextIntent = PendingIntent.getService(
            this, 2,
            Intent(this, MediaPlaybackService::class.java).apply { action = ACTION_NEXT },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = PendingIntent.getService(
            this, 3,
            Intent(this, MediaPlaybackService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val playPauseIcon = if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
        val playPauseTitle = if (isPlaying) "Pause" else "Play"

        val artwork = loadArtworkBitmap()

        val style = Notification.MediaStyle()
            .setMediaSession(mediaSession?.sessionToken)
            .setShowActionsInCompactView(0, 1, 2)

        val builder = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle(currentTitle)
            .setContentText(currentArtist)
            .setSubText(currentAlbum)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(contentIntent)
            .setDeleteIntent(stopIntent)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(isPlaying)
            .setStyle(style)
            .addAction(Notification.Action.Builder(
                android.R.drawable.ic_media_previous, "Previous", prevIntent
            ).build())
            .addAction(Notification.Action.Builder(
                playPauseIcon, playPauseTitle, playPauseIntent
            ).build())
            .addAction(Notification.Action.Builder(
                android.R.drawable.ic_media_next, "Next", nextIntent
            ).build())

        if (artwork != null) {
            builder.setLargeIcon(artwork)
        }

        return builder.build()
    }

    private fun loadArtworkBitmap(): Bitmap? {
        val path = currentArtworkPath ?: return null
        artworkCache[path]?.let { return it }

        return try {
            if (path.startsWith("http://") || path.startsWith("https://")) {
                fetchRemoteArtwork(path)
                null
            } else {
                val file = File(path)
                if (file.exists()) {
                    val opts = BitmapFactory.Options().apply {
                        inSampleSize = 2
                    }
                    val bmp = BitmapFactory.decodeFile(path, opts)
                    if (bmp != null) {
                        artworkCache[path] = bmp
                    }
                    bmp
                } else null
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun fetchRemoteArtwork(urlStr: String) {
        Thread {
            try {
                val url = java.net.URL(urlStr)
                val connection = url.openConnection() as java.net.HttpURLConnection
                connection.connectTimeout = 4000
                connection.readTimeout = 4000
                connection.doInput = true
                connection.connect()
                val input = connection.inputStream
                val bmp = BitmapFactory.decodeStream(input)
                input.close()
                if (bmp != null) {
                    artworkCache[urlStr] = bmp
                    if (currentArtworkPath == urlStr) {
                        mainHandler.post {
                            updateMediaSessionMetadata()
                            showNotification()
                        }
                    }
                }
            } catch (_: Exception) {}
        }.start()
    }

    private fun showNotification() {
        try {
            val notification = buildNotification()
            notificationManager?.notify(NOTIFICATION_ID, notification)
        } catch (_: Exception) {}
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        val playing = try { activePlayer?.isPlaying ?: false } catch (_: Exception) { false }
        if (playing) {
            try {
                stopForeground(STOP_FOREGROUND_REMOVE)
                notificationManager?.cancel(NOTIFICATION_ID)
            } catch (_: Exception) {}
        } else {
            try {
                stopForeground(STOP_FOREGROUND_REMOVE)
                notificationManager?.cancel(NOTIFICATION_ID)
                activePlayer?.apply {
                    reset()
                    release()
                }
                activePlayer = null
                isPlayerPrepared = false
            } catch (_: Exception) {}
            stopSelf()
        }
    }

    override fun onDestroy() {
        mediaSession?.apply {
            isActive = false
            release()
        }
        mediaSession = null
        try {
            activePlayer?.apply {
                reset()
                release()
            }
            activePlayer = null
            isPlayerPrepared = false
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
