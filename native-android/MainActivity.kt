package com.focusguard.app

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.net.VpnService
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowRight

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            FocusGuardTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    SetupScreen()
                }
            }
        }
    }

    @Composable
    fun SetupScreen() {
        Column(
            modifier = Modifier.fillMaxSize().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Top
        ) {
            Spacer(modifier = Modifier.height(40.dp))
            Text("FocusGuard", fontSize = 32.sp, fontWeight = FontWeight.ExtraBold, color = Color(0xFF2563EB))
            Text("Permission Management", fontSize = 16.sp, fontWeight = FontWeight.Medium, color = Color.Gray)
            
            Spacer(modifier = Modifier.height(48.dp))
            
            PermissionCard(
                title = "Accessibility Service",
                description = "Required to detect when social media apps are opened.",
                icon = "⚙️",
                onClick = {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                }
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            PermissionCard(
                title = "Usage Access",
                description = "Required to track app session duration and enforce limits.",
                icon = "📊",
                onClick = {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                }
            )

            Spacer(modifier = Modifier.height(16.dp))
            
            PermissionCard(
                title = "Authorize Network Blocker",
                description = "Local VPN setup to toggle connectivity on Android 10+.",
                icon = "🛡️",
                onClick = {
                    val intent = VpnService.prepare(this@MainActivity)
                    if (intent != null) {
                        startActivityForResult(intent, 0)
                    }
                }
            )

            Spacer(modifier = Modifier.weight(1f))
            
            Button(
                onClick = { /* Check if permissions authorized then proceed */ },
                modifier = Modifier.fillMaxWidth().height(56.dp),
                shape = MaterialTheme.shapes.large
            ) {
                Text("Continue to Dashboard", fontWeight = FontWeight.Bold)
            }
            Spacer(modifier = Modifier.height(24.dp))
        }
    }

    @Composable
    fun PermissionCard(title: String, description: String, icon: String, onClick: () -> Unit) {
        Card(
            onClick = onClick,
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE5E7EB))
        ) {
            Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(icon, fontSize = 24.sp)
                Spacer(modifier = Modifier.width(16.dp))
                Column {
                    Text(title, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                    Text(description, fontSize = 12.sp, color = Color.Gray)
                }
                Spacer(modifier = Modifier.weight(1f))
                Icon(
                    imageVector = Icons.Default.KeyboardArrowRight,
                    contentDescription = null,
                    tint = Color.LightGray
                )
            }
        }
    }
}

@Composable
fun FocusGuardTheme(content: @Composable () -> Unit) {
    MaterialTheme(content = content)
}
