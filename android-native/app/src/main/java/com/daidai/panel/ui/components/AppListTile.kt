package com.daidai.panel.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.core.theme.LocalGlassMode

@Composable
fun AppListTile(
    icon: ImageVector,
    title: String,
    glassMode: Boolean? = null,
    onClick: (() -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val isLight = !isSystemInDarkTheme()
    val effectiveGlassMode = glassMode ?: LocalGlassMode.current
    val shape = RoundedCornerShape(16.dp)

    if (effectiveGlassMode) {
        GlassCard(
            modifier = modifier.fillMaxWidth(),
            padding = androidx.compose.foundation.layout.PaddingValues(0.dp),
            onClick = onClick
        ) {
            ListItem(
                headlineContent = {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.bodyLarge
                    )
                },
                leadingContent = {
                    Icon(
                        imageVector = icon,
                        contentDescription = title,
                        tint = AppColors.primary,
                        modifier = Modifier.size(24.dp)
                    )
                },
                trailingContent = trailing,
                colors = ListItemDefaults.colors(
                    containerColor = Color.Transparent
                )
            )
        }
    } else {
        Row(
            modifier = modifier
                .fillMaxWidth()
                .clip(shape)
                .background(
                    color = MaterialTheme.colorScheme.surface,
                    shape = shape
                )
                .border(
                    width = 0.5.dp,
                    color = MaterialTheme.colorScheme.outlineVariant,
                    shape = shape
                )
                .then(
                    if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier
                )
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                tint = AppColors.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                modifier = Modifier.weight(1f)
            )
            if (trailing != null) {
                trailing()
            }
        }
    }
}
