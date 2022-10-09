# P2: Documentation in Files
### P2 Solution

As part of MP2, you will also write a device driver for the Tux controller boards in the lab. The documentation for this board can be found in the file mtcp.h in the class directory under mp2. You will need to read it for the following questions.

## Q1

1. For each of the following **messages** sent from the computer to the Tux controller, briefly explain：
   - **when** it should be sent, **what effect** it has on the device and **what message(s)** are returned to the computer as a result of 
     -  **MTCP BIOC ON, MTCP LED SET**

#### Opcode: MTCP_BIOC_ON

- When: System starts

- Enable **Button interrupt-on-change(BIOC).**

- Return : **MTCP_ACK** 
  - value == MTCP_RESP(0x00) == 0x40, Response when the MTC successfully completes a command.
  - ACK may be short for *acknowledgement*

#### Opcode MTCP_LED_SET

- When: When the LED display is in USR mode( See reference below for more details)

  - The first byte of argument specifies  which of the LED's to set, and also determines how many bytes will follow - one byte for each led to set.
  - The following bytes specify which of the LED's in the 7-segment display should be turned on

- Function: Set the User-set LED display values, which will be displayed on the LED displays 

- Return:  

  - Response: 1 byte
  - byte 0 - MTCP_ACK -- meaning succeed
  - if there's no signal, then the Opcode fail
  
  ![P1](https://gitlab.engr.illinois.edu/ece391_fa22/ps2_ngao4/-/raw/master/p2/LED.png)
  
### Reference on the related signal:
> 1. The exact value of signal is computed by the following macro instruction:
> **#define MTCP_RESP(n)	(((n)&7) | (((n)&0x18)<<1) | 0x40)**
> 
> 2. MTCP_LED_USR:
> - Put the LED display into user-mode. In this mode, the value specified by the MTCP_LED_SET command is displayed.
>
> 3. MTCP_LED_CLK:
> - Put the LED display into clock mode. In this mode, the value of the clock is displayed, rather than the value set with MTCP_LED_SET.

## Q2
For each of the following messages sent from the Tux controller to the computer, briefly explain when the device sends the message and what information is conveyed by the message:

   - **MTCP ACK**: MTCP_RESP(0x00) == 0x40

     -  Response when the MTC successfully completes a command
     -  -> This signal doesn't really contain any actual data. It's just a response to make sure the program's command runs correctly

       

   - **MTCP BIOC EVENT**: MTCP_RESP(0x1) == 0x41

     - Generated when the ***Button Interrupt-on-change*** mode is enabled and a button is either pressed or released.

     - Packet format:

          ![P2](https://gitlab.engr.illinois.edu/ece391_fa22/ps2_ngao4/-/raw/master/p2/MTCP_BIOC_EVENT.png)
          
          Here, the signal is a packet consist of 3 bytes, first byte specifies the operand. Second and third byte convey the pushed button on the MTC.

   - **MTCP RESET**: MTCP_RESP(0x6)
     
     -  Generated when the device re-initializes itself after a power-up,  a RESET button press, or an MTCP_RESET_DEV command.	
     
       Packet Format:
     
       - Byte 0 - MTCP_RESET                   Operand
     
       - Byte 1 - reserved                          Useless, don't convey any information
     
       - Byte 2 - reserved                          Useless, don't convey any information

   

## Q3: 

   Now read the function header for tuxctl handle packet in tuxctl-ioctl.c —you will have to follow the pointer there to answer the question, too. In some cases, you may want to send a message to the Tux controller in response to a message just received by the computer (using tuxctl ldisc put). However, if the output buffer for the device is full, you cannot do so immediately. Nor can the code (executing in tuxctl handle packet) wait (e.g., go to sleep). 

   **Explain in one sentence why the code cannot wait**
### Ans:

If the code wait for that, then the whole system will be halt for 9ms, which can be unacceptable for an interrupt handling program, because the ioctls should return immediately with success if their parameters are valid.

### Reference to the comment:

>  **IMPORTANT NOTE: READ THIS BEFORE IMPLEMENTING THE IOCTLS**
>
>  ---
>
>  * The ioctls should not spend any time waiting for responses to the commands 
>  * they send to the controller. The data is sent over the serial line at      
>  * 9600 BAUD. At this rate, a byte takes approximately 1 millisecond to       
>  * transmit; this means that there will be about 9 milliseconds between       
>  * the time you request that the low-level serial driver send the     
>  * 6-byte SET_LEDS packet and the time the 3-byte ACK packet finishes 
>  * arriving. This is far too long a time for a system call to take. The      
>  * ioctls should return immediately with success if their parameters are valid.                                                               
>  ---
