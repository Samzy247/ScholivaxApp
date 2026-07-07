package com.scholivax.app.ui.common

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.scholivax.app.data.local.AppDatabase
import com.scholivax.app.data.local.CachedCircular
import com.scholivax.app.data.remote.ApiClient
import com.scholivax.app.databinding.ActivityCircularsBinding
import com.scholivax.app.databinding.RowCircularBinding
import kotlinx.coroutines.launch

class CircularsActivity : AppCompatActivity() {

    private lateinit var binding: ActivityCircularsBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityCircularsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.swipeRefresh.setOnRefreshListener { refresh() }
        loadFromCacheThenRefresh()
    }

    private fun loadFromCacheThenRefresh() {
        lifecycleScope.launch {
            val db = AppDatabase.getInstance(this@CircularsActivity)
            render(db.circularDao().getAll())
            refresh()
        }
    }

    private fun refresh() {
        lifecycleScope.launch {
            binding.swipeRefresh.isRefreshing = true
            val db = AppDatabase.getInstance(this@CircularsActivity)
            try {
                val api = ApiClient.create(this@CircularsActivity)
                val response = api.getCirculars(sinceId = 0)
                val circulars = response.body()?.circulars
                if (response.isSuccessful && circulars != null) {
                    db.circularDao().insertAll(circulars.map {
                        CachedCircular(it.circular_id, it.title, it.reference, it.content, it.date)
                    })
                    render(db.circularDao().getAll())
                }
            } catch (e: Exception) {
                // Offline — what's already rendered from cache stands.
            } finally {
                binding.swipeRefresh.isRefreshing = false
            }
        }
    }

    private fun render(circulars: List<CachedCircular>) {
        binding.circularsContainer.removeAllViews()
        for (c in circulars) {
            val row = RowCircularBinding.inflate(layoutInflater, binding.circularsContainer, false)
            row.circularTitle.text = c.title ?: "(untitled)"
            row.circularDate.text = c.date ?: ""
            row.circularContent.text = c.content ?: ""
            binding.circularsContainer.addView(row.root)
        }
    }
}
