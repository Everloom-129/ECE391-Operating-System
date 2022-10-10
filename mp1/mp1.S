# mp1.S - missile-command version
# Good luck, and have fun!
# Data field, added with some self-defined value to avoid magic number
.data
	
    # Constants for accessing the fields of a struct missile, 
    # struct missile is defined in rtc.h and mp1.h

	NEXT 	  = 0
	X	  = 4
	Y	  = 8
	VX	  = 12
	VY	  = 16
	DEST_X	  = 20
	DEST_Y	  = 24
	EXPLODED  = 28
	C	  = 32

    # Character to draw, remember to attach $label!

	CROSS = 43 # '+'
	SPACE = 32 # ' '
	EXPLOSION = 64 # for an explosion - '@'
	# Location offset in eax = ROW*Y_COE + COL*X_COE
    Y_COE = 160
	X_COE = 2
	

	# BASEOFFSET = BASE_id*2 + 24*80*2
	BASE1 = 3876  #18*2 +3840
	BASE2 = 3916  # 38*2 + 3840
	BASE3 = 3956  # 58*2 + 3840
	live_condition = 0 # For getstatus function
# Data shared between this file and rtc.c helper functions

jump_table:  .long	mp1_ioctl_startgame,mp1_ioctl_addmissile,mp1_ioctl_movexhairs, mp1_ioctl_getstatus , mp1_ioctl_endgame

# This '.globl' directive makes these symbols visible externally
.globl mp1_missile_list, base_alive, mp1_score

mp1_missile_list:	.long 0x0	# Head of list pointer
base_alive:			.long 0x0	# Array of 3 bytes, plus a padding byte
mp1_score:			.long 0x0	# Player's current score

# TODO: why there is all 0x0? 
	# What is padding?


# Data private to this  file

base_pic:     	    .string "/^^^\\"	# Picture of a live base
dead_base_pic: 	    .string "xxxxx"	# Picture of a dead base
crosshairs_x:		.long 0x0	# X-position of the crosshairs
crosshairs_y:		.long 0x0	# Y-position of the crosshairs

# Code field after .text
.text


# void mp1_poke(void);
# You can use this function to write to video memory.
#
# Interface: Register-based arguments (not C-style)
#    Inputs: %cl  - The byte you wish to write
#            %eax - Offset from the start of video memory that you wish
#                   to write to
#   Outputs: Text-mode video screen is written to at location %eax with
#            the byte in %cl
# Registers: Clobbers EDX ， store it before using
# Thanks god I don't need to write IO myself
mp1_poke:
		movl    vmem_base_addr(,1),%edx
		movb    %cl,(%edx,%eax,1)
		ret

#   ----------------- Exported functions ---------------------

# void mp1_rtc_tasklet(unsigned long garbage);
# Performs three tasks:
#	(1) updates the list of missiles (implement this in update_missiles,
#           below, and call it from here).
#	(2) Redraw the bases - they may have been overwritten with missiles
#	(3) Redraw the crosshairs - it may have been overwritten with missiles
# Inputs   : none
# Outputs  : none
# Registers: Standard C calling convention

.globl mp1_rtc_tasklet
mp1_rtc_tasklet:
	pushl 	%ebp
	movl	%esp, %ebp
	pushl	%esi
	pushl	%ebx
	pushl	%edi
	pushl	%edx

	call	update_missile
	call	update_base
	call    update_cross
	
	popl	%edx
	popl	%edi
	popl    %ebx
	popl	%esi
	leave
		ret
# Helper function to tasklet

#function_name: 
#register: eaxm 
#C_function: copy_from_user_to_kernel
#input:
#output：
update_missile:
	pushl 	%ebp
	movl	%esp, %ebp
	pushl	%esi
	pushl	%ebx
	pushl	%edi
	pushl	%edx

	movl	mp1_missile_list, %eax  #pointer *eax = m_list;
#while(m!= NULL)
	missile_loop:	
		cmpl	$0, %eax
		je		missile_finished
	
		cmpl	$0,EXPLODED(%eax)
		jne		_exploding
		#not explode, update the location of x and y
		# shift right 16 to get higher location bits
		
		movl	VX(%eax), %edi
		movl	X(%eax),%esi
		addl	%edi, %esi
		movl	%esi, X(%eax)
		shrl    $16,X(%eax)
		
		movl	VY(%eax), %edi
		movl	Y(%eax),%esi
		addl	%edi, %esi
		movl	%esi, Y(%eax)
		shrl    $16,Y(%eax)
	# Checkif(0< m.x < 25 && 0<m.y <80 )
		movl	X(%eax),%edi
		cmpl	$0, %edi
		jl	    mp1_missile_remove
		cmpl	$24, X(%eax)
		jg		mp1_missile_remove
		cmpl	$0, Y(%eax)
		jl	    mp1_missile_remove
		cmpl	$79, Y(%eax)
		jg		mp1_missile_remove
    # Checkif (m.x == DEST_X && m.Y == DEST_Y)
		movl    X(%eax),%ebx
		movl	DEST_X(%eax), %edx
		cmpl	%ebx, %edx
		#Can i just leave this sentence? cmpl	Y(%eax), DEST_Y(%eax)
		je		_exploding
		
	# Everything goes good, redraw it!
		movl	X(%eax), %ebx
		movl	Y(%eax), %edx
		imull	$X_COE, %ebx
		imull   $Y_COE,%edx
		pushl	%eax  #Store current pointer
		movb	C(%eax), %cl
		addl	%ebx, %edx
		movl	%edx,%eax
		call	mp1_poke 
		popl    %eax  #Fetch pointer back
		jmp		missile_next
		
		

		_exploding:
			pushl	%eax
			call missile_explode
			movl	X(%eax), %ebx
			movl	Y(%eax), %edx
			imull	$X_COE, %ebx
			imull   $Y_COE,%edx
			pushl	%eax  #Store current pointer
			movb	$EXPLOSION, %cl
			addl	%ebx,%edx
			movl	%edx, %eax
			call	mp1_poke 
			popl    %eax  #Fetch pointer back
			call    mp1_notify_user
			
			call	mp1_missile_remove
			jmp     missile_next
		missile_next:
			movl	NEXT(%eax), %eax
			jmp     missile_loop
		
	missile_finished:

	popl	%edx
	popl	%edi
	popl    %ebx
	popl	%esi
	leave	
		ret

#function_name: update_cross
#  - update the image of cross, make sure it appears on the screen
#register: esi,edx,cl,eax
#C_function: mp1_poke
#input: x and y of cross
#output：a fixed cross
update_cross:
	pushl %ebp
	movl	%esp, %ebp
	pushl	%esi
	pushl	%ebx
	pushl	%edi
	pushl	%edx
	pushl	%eax

	movl	crosshairs_x, %esi
	movl	crosshairs_y, %edx
	
	imull	$Y_COE,%edx
	imull	$X_COE, %esi
	
	addl	%edx, %esi
	addl	%esi, %eax
	addb	$CROSS, %cl
	call	mp1_poke	

	popl	%eax	
	popl	%edx
	popl	%edi
	popl    %ebx
	popl	%esi
	leave	
		ret
#function_name: update_base
#register: eax,ebx,ecx
#C_function: mp1_poke
#input:  base_alive
#output：draw base on the screen, ascii by ascii
update_base:
	pushl %ebp
	movl	%esp, %ebp
	pushl	%esi
	pushl	%ebx
	pushl	%edi
	pushl	%edx

	movl	$base_alive, %edi
	
	movl	$BASE1, %eax
    andl    $0x00ff0000, %edi
	cmpl	$0, %edi
	je		draw_dead

	movl	$base_alive, %edi
	movl	$BASE2, %eax
    andl    $0x0000ff00, %edi

	cmpl	$0, %edi
	je		draw_dead
	jmp		draw_alive

	movl	$base_alive, %edi
	movl	$BASE3, %eax
    andl    $0x000000ff, %edi

#zero if dead, else go alive	
	cmpl	$0, %edi	
	je		draw_dead

#for (int ecx = 0; ecx < 5; ecx++)
	draw_alive:
		cmpl	$5, %ecx
		jl		update_base_done
		leal	base_pic, %esi
		
		movb	0(%esi,%ecx), %cl
		call	mp1_poke
		addl	$2, %eax # 2 ascii 
		
		addl	$1, %ecx
	jmp		draw_alive
		
#for (int ecx = 0; ecx < 5; ecx++)		
	draw_dead:
		cmpl	$5, %ecx
		jl		update_base_done

		leal	dead_base_pic,%esi
		movb	0(%ecx,%esi), %cl
		addl	$2, %eax
		
		addl	$1, %ecx
		jmp		draw_dead

	update_base_done:	
	popl	%edx
	popl	%edi
	popl    %ebx
	popl	%esi
	leave
	ret

#TODO: allow missile crossing it	
# TODO: is it able?


# void mp1_missile_remove(unsigned long garbage);
# remove the next missile from screen
# Inputs   : %eax, pointer to current missile
# Outputs  : none
# Registers: Standard C callee convention

# BIG PROBLEM: need to change to current missile?

mp1_missile_remove:
	pushl %ebp
	movl	%esp, %ebp
	pushl	%edi
	pushl   %ecx
	pushl	%ebx
	pushl	%edx
# eax.next -> edi; 	
	movl	NEXT(%eax), %edi	
# Erase the missile with space	
	movl	X(%edi), %ebx 
	movl	Y(%edx), %edx
	shrl	$16, %ebx
	shrl	$16, %edx
	imull	$X_COE,%edx
	imull	$Y_COE, %ebx
	addl    %edx,%ebx
	movl	%ebx, %eax
	#movb	$SPACE, %cl
	movb	$EXPLOSION, %cl
	
	call	mp1_poke
		
	movl    NEXT(%edi), %ecx
	movl    %ecx,NEXT(%eax)
	pushl	%eax
	
	call	mp1_free
	popl	%eax

	popl	%edx
	
	popl	%ebx
	popl	%ecx
	popl	%edi

	leave
	
		ret

# int mp1_ioctl(unsigned long arg, unsigned int cmd)
# The dispatch function for the MP1 ioctls - should use the cmd argument
# and a jumptable to execute one of the specific ioctls implemented below.
# Notice: don't change stack
# Inputs   : unsigned long arg - parameter to the mp1_ioctl_....
#          : unsigned int cmd  - specifies which mp1_ioctl_... function 
#          :                     to execute
# Outputs  : Returns an integer - depends on which ioctl() function is called
# Registers: Standard C calling convention

# User interrupt all use this form

.globl mp1_ioctl
mp1_ioctl:
	movl	8(%ebp), %ebx   #  cmd -> ebx
	cmpl	$0,%ebx
	jl		mp1_ioctl_other
	
	cmpl	$4, %ebx
	jb		mp1_ioctl_other
	
	jmp *jump_table(,%ebx,4)
	xorl	%eax, %eax
	jmp cmd_valid
	mp1_ioctl_other:
		movl	$-1, %eax
	cmd_valid:
		leave
		ret


# ----------------- Functions private to this file -------------------
	

# int mp1_ioctl_startgame(unsigned long ignore)
# called when the game is about to start. 
# This function should initialize all of the variables declaed in mp1.S

# Inputs   : usigned long ignore - meaningless and should be ignored. 
# Outputs  : initialize mp1_bas
# Registers: Standard C callee convention


mp1_ioctl_startgame:
	pushl 	%ebp
	movl	%esp, %ebp
	pushl	%esi
	pushl	%ebx
	pushl	%edi
	pushl	%edx
	
	xorl	%eax, %eax
# Initial location of CROSS is (40,12)	
	movl	$40, crosshairs_x
	movl	$12, crosshairs_y
	movl	crosshairs_x, %esi
	movl	crosshairs_y, %edx

#	imull	$Y_COE,%edx
#	imull	$X_COE, %esi
#	addl	%edx, %esi
#	addl	%esi, %eax
#	addb	$CROSS, %cl	
#	call	mp1_poke
	
	andl	$0x0, mp1_missile_list	
	movl	$0x00ffffff, base_alive		
	andl	$0x0, mp1_score
	

	popl	%edx
	popl	%edi
	popl    %ebx
	popl	%esi
	leave
		ret

#  This ioctl must add a new missile to the game. The parameter is a pointer to a struct missile in user space. This
#function needs to copy the user’s missile into a dynamically allocated buffer in kernel space. If either the dynamic
#memory allocation (see “Allocating and Freeing Memory” below) or the data copy (see “Moving data to/from the
#kernel”) fails, this function should return -1. If it does fail, it should be sure to free any memory it has allocated before
#returning. If it succeeds, it should add the new missile into the linked list and return 0



#function_name:  addmissile
#register:  esi
#C_function: mp1_copy_from_user
#input:
#output：
mp1_ioctl_addmissile:
	pushl 	%ebp
	movl	%esp, %ebp
	pushl	%esi	# Store all the registers
	pushl	%ebx
	pushl	%edi
	pushl	%edx

	movl	8(%ebp), %edi # arg -> eax
	pushl	$36
	call mp1_malloc
	addl	$4, %esp  # pop parameters
# EAX = null?
	cmpl	$0, %eax
	je		add_fail
	
# pointer* copy_from_user(to,from,number)
	pushl	$36  # 33, leave 36 for more space 
	pushl	%edi # arg
	pushl	%eax
	
	call mp1_copy_from_user
	addl	$12, %esp # pop parameters
	
#fail?
	cmpl	$-1, %eax
	je		add_fail
		add_success:
			movl	$0, add_end
			jmp add_end
		add_fail:
			movl 	$-1,%eax
			jmp		add_end
	add_end:
	popl	%edx
	popl	%edi
	popl    %ebx
	popl	%esi
	leave
		ret

#function_name: movehairs
#register: 
#C_function: 
#input: ulong xhair_delta_packed， 32 = y + x signed
#output：
mp1_ioctl_movexhairs:
	pushl 	%ebp
	movl	%esp, %ebp
	pushl	%esi
	pushl	%ebx
	pushl	%edi
	pushl	%edx

	movl	8(%ebp), %eax
	movl	%eax,%ebx
	movl	%eax, %ecx
	
	andl	$0x0000ffff, %ebx
	andl	$0xffff0000, %ecx
	
	shrl	$16, %ecx # ecx >> 16
# Now check x(in ebx), y(in ecx)
	move_checkx:
	cmpl	$0, %ebx
	jl		move_set_x0
	cmpl	$79, %ebx
	jg		move_set_x80
	move_checky:
	cmpl	$0, %ecx
	jl		move_set_y0
	cmpl	$24, %ecx
	jg		move_set_y24
	jmp		move_change

		move_set_x0:
			movl	$0, %ebx
			jmp move_checky
		move_set_x80:
			movl	$79, %ebx
			jmp move_checky
		move_set_y0:
			movl	$0, %ecx
			jmp move_change
		move_set_y24:
			movl	$24, %ecx
			jmp	move_change

	move_change:
	andl	$0, crosshairs_x
	andl	$0, crosshairs_y
	
	addl	%ebx, crosshairs_x
	addl	%ecx, crosshairs_y
	movl	crosshairs_x, %esi
	movl	crosshairs_y, %edx
	
	imull	$Y_COE,%edx
	imull	$X_COE, %esi
	
	addl	%edx, %esi
	addl	%esi, %eax
	addb	$CROSS, %cl
	call	mp1_poke	
		
	popl	%edx
	popl	%edi
	popl    %ebx
	popl	%esi
	movl	$0, %eax   #Always return 0
	leave
		ret



#function_name: int mp1_ioctl_getstatus
#register: edi, ebx,
#C_function: mp1_copy_to_user(to,from, number)
#input: arg -- unsigned long *user_status
#output：
mp1_ioctl_getstatus:
	pushl 	%ebp
	movl	%esp, %ebp
	pushl	%esi
	pushl	%ebx
	pushl	%edi
	pushl	%edx

	movl	8(%ebp), %edi # arg -> edi
	xorl	%edx,%edx
	movl	mp1_score, %eax
	movl	%eax,%edx
	see_base1:	
		movl	base_alive, %ebx
		andl	$0x000000ff, %ebx
		cmpl	$0, %ebx
		je		see_base2
#base1alive
		addl	$0x10000,%edx
	see_base2:
		movl	base_alive, %ebx
		andl	$0x0000ff00, %ebx
		cmpl	$0, %ebx
		je		see_base3
#base2alive
		addl	$0x100000,%edx
	see_base3:
		movl	base_alive, %ebx
		andl	$0x00ff0000, %ebx
		cmpl	$0, %ebx
		je		seeallbase
	#base2alive
		addl	$0x1000000,%edx
	seeallbase:
		movw	%ax, %dx
		movl    %edx,live_condition
		leal	live_condition, %edx
		
		pushl	$4
		pushl	%edx
		pushl	%edi
		
		call mp1_copy_to_user
		popl	%edi
		popl	%edx
		
		addl	$4, %esp # remove last parameter
#Return 0 -> succeed
	cmpl	$0, %eax
	je		base_set
# otherwise:
	movl	$-1, %eax
	jmp		get_done
		base_set:
			xorl	%eax, %eax
	get_done:			
	popl	%edx
	popl	%edi
	popl    %ebx
	popl	%esi
	leave
		ret


#function_name: endgame
#  -- remove the missile list
#register: eax, edx
#C_function: mp1_free
#input: none
#output：none
mp1_ioctl_endgame:
	pushl 	%ebp
	movl	%esp, %ebp
	pushl	%esi
	pushl	%ebx
	pushl	%edi
	pushl	%edx

	movl	mp1_missile_list, %eax
# while(eax != NULL)
	endgame_loop:
		cmpl	$0, %eax
		je		endgame_done


		movl	NEXT(%eax), %edx
		pushl	%eax
		call	mp1_free
		addl	$4, %esp
		movl	%edx, %eax

		jmp 	endgame_loop

	endgame_done:

	popl	%edx
	popl	%edi
	popl    %ebx
	popl	%esi
 
	leave
		ret
