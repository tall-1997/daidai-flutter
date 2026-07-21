package com.daidai.panel.ui.components

import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.core.theme.LocalGlassMode

@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    borderRadius: Dp = 16.dp,
    padding: PaddingValues = PaddingValues(16.dp),
    glassMode: Boolean? = null,
    onClick: (() -> Unit)? = null,
    content: @Composable () -> Unit
) {
    val isLight = !isSystemInDarkTheme()
    val effectiveGlassMode = glassMode ?: LocalGlassMode.current
    val shape = RoundedCornerShape(borderRadius)

    val cardModifier = modifier
        .clip(shape)
        .then(
            if (effectiveGlassMode && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                Modifier
                    .background(Color.Transparent)
                    .glassBlur(20f)
                    .background(
                        color = if (isLight) AppColors.glassCard else Color(0x991E293B),
                        shape = shape
                    )
            } else if (effectiveGlassMode) {
                Modifier.background(
                    color = if (isLight) Color(0xCCFFFFFF) else Color(0xCC1E293B),
                    shape = shape
                )
            } else {
                Modifier.background(
                    color = MaterialTheme.colorScheme.surface,
                    shape = shape
                )
            }
        )
        .border(
            width = 0.5.dp,
            color = if (effectiveGlassMode) {
                if (isLight) AppColors.glassCardBorder else Color(0x33334155)
            } else {
                MaterialTheme.colorScheme.outlineVariant
            },
            shape = shape
        )

    val clickableModifier = if (onClick != null) {
        Modifier.clickable(onClick = onClick)
    } else {
        Modifier
    }

    Box(
        modifier = cardModifier.then(clickableModifier).padding(padding)
    ) {
        content()
    }
}
