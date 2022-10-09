### P1 Solution

# P1: Reading Device Documentation

## Solution

Here is a great website for VGA related info that you might find useful: http://www.osdever.net/FreeVGA/vga/vga.htm

## Q1: You must use VGA support to add a non-scrolling status bar. 

- Figure out how to use VGA **registers** to separate the screen into two distinct regions. 
- Explain the **necessary register value settings**, **how the VGA acts upon them,** and any relevant **constraints** that must be obeyed when setting up the status bar.

### Answer:

   - The screen realization technique a mapping of display memory into CPU address Space. The display memory start from A0000h to BFFFFh.  To add a non-scrolling status bar, we need to can specify a horizontal division which divides the screen into two windows. This two windows start at separate display memory addresses. That requires us to  use these following registers: 

     - **Overflow Register (Index 07h)**
     - **Preset Row Scan Register (Index 08h)**
     - **Line Compare Register & Maximum Scan Line Register (Index 09h)** (bit 07 share with each other)

     > The Line Compare field in the VGA, of which bit 9 is in the [Maximum Scan Line Register](http://www.osdever.net/FreeVGA/vga/crtcreg.htm#09), bit 8 is in the [Overflow Register](http://www.osdever.net/FreeVGA/vga/crtcreg.htm#07), and bits 7-0 are in the [Line Compare Register](http://www.osdever.net/FreeVGA/vga/crtcreg.htm#18), specifies the scan line address of the horizontal division. When the line counter reaches the value in the Line Compare

     The realization of separating screen is to set scan register with given value,  makes it stop line scanning at the given horizontal line. Then we reset the row scan register, turning the VGA into next window mapping. This process has the following pseudocode:

     ```c
     //Draw first window:
     Line compare register = the location of screen to split
     while( Preset Row Scan Register < Line compare register){
     	line scanning from the memory;
         draw value on the screen pixel by pixel;
         row scan register --;
     }
     //Draw Second Window:
     Reset row scan register;
     while( int counter = current location line <= location of screen's bottom ){
     	line scanning from the memory;
         draw value on the screen pixel by pixel;
         counter --;
     }
     ```

     

   - **Constraints:**

     - the first being that the bottom window's starting display memory address is fixed at 0

       - the bottom screen must be located first in memory and followed by the top

     - The Panning mode value should be fixed at 0, to make sure the status bar don't scroll. 

       -  either both windows are panned by the same amount, or only the top window pans

     - The [Preset Row Scan](http://www.osdever.net/FreeVGA/vga/crtcreg.htm#08) field only applies to the top window -- the bottom window has an effective Preset Row Scan value of 0


### Reference:

> This field specifies bits 7-0 of the Line Compare field. Bit 9 of this field is located in the Maximum Scan Line Register, and bit 8 of this field is located in the Overflow Register. The Line Compare field specifies the scan line at which a horizontal division can occur, providing for split-screen operation. If no horizontal division is required, this field should be set to 3FFh. When the scan line counter reaches the value in the Line Compare field, the current scan line address is reset to 0 and the Preset Row Scan is presumed to be 0. If the Pixel Panning Mode field is set to 1 then the Pixel Shift Count and Byte Panning fields are reset to 0 for the remainder of the display cycle.

## Q2: You must change the VGA’s color palette. 

- Figure out how to do so, and explain the sequence of register operations necessary to set a given color to a given 18-bit RGB (red, green, blue) value.

### Answer:

1. Load the palette entry's index value to the DAC Address Write Mode Register
2. Load the red, green, then blue values into the DAC Data Register in the RGB sequence.
3. The internal write address automatically increments so that it allows the next value's RGB values to be loaded 



### Reference:

> The Color Registers in the standard VGA provide a mapping between the palette of between 2 and 256 colors to a larger 18-bit color space. This capability allows for efficient use of video memory while providing greater flexibility in color choice. The standard VGA has 256 palette entries containing six bits each of red, green, and blue values. The palette RAM is accessed via a pair of address registers and a data register. To write a palette entry, output the palette entry's index value to the [DAC Address Write Mode Register](http://www.osdever.net/FreeVGA/vga/colorreg.htm#3C8) then perform 3 writes to the [DAC Data Register](http://www.osdever.net/FreeVGA/vga/colorreg.htm#3C9), loading the red, green, then blue values into the palette RAM. The internal write address automatically advances allowing the next value's RGB values to be loaded without having to reprogram the [DAC Address Write Mode Register. This](http://www.osdever.net/FreeVGA/vga/colorreg.htm#3C8) allows the entire palette to be loaded in one write operation. To read a palette entry, output the palette entry's index to the [DAC Address Read Mode Register](http://www.osdever.net/FreeVGA/vga/colorreg.htm#3C7W). Then perform 3 reads from the [DAC Data Register](http://www.osdever.net/FreeVGA/vga/colorreg.htm#3C9), loading the red, green, then blue values from palette RAM. The internal write address automatically advances allowing the next RGB values to be written without having to reprogram the [DAC Address Read Mode Register](http://www.osdever.net/FreeVGA/vga/colorreg.htm#3C7W).
