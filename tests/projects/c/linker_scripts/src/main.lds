SECTIONS
{
  . = 0x10000;
  .text : { *(.text) }
  .init_array :
  {
      PROVIDE_HIDDEN (__init_array_start = .);
      KEEP (*(SORT(.init_array.*)))
      KEEP (*(.init_array*))
      PROVIDE_HIDDEN (__init_array_end = .);
  }
  . = 0x8000000;
  .data : { *(.data) }
  .bss : { *(.bss) }
}
