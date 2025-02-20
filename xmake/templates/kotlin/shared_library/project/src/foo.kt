@file:OptIn(ExperimentalNativeApi::class)

import kotlin.experimental.ExperimentalNativeApi
import kotlinx.cinterop.*

@ExperimentalNativeApi
@CName("kotlin_add")
fun add(a: Int, b: Int): Int = a + b
