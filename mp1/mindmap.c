// Mindmap of solving mp1
// JIE WANG
// Have already asked professor for extension 

// callee_save vs caller_save
// logic first, then come the code
// main program is beautiful
// space: $32
// @:     %64

#include<stdio.h>

void update_missile(m_list){
    pointer *m = m_list;
// loop1
    while(m != NULL){
        if(m.EXBLODED == 0)
            m.x = m.x + m.vx
            m.y = m.y + m.vy

            if(0< m.x < 25 && 0<m.y <80  ){
                if (m.x =!= DEST_X && m.Y != DEST_Y)
                {
               
                // simply moving, redraw its location
                {
                offset = x*x_coe + y*y_coe
                eax = offset
                cl = m.C
                call mp1_poke
                
            }else{
            mp1_missile_remove(m)
            next
            }
            
            

        }else{
            missile_explode(m)
                
                offset = x*x_coe + y*y_coe
                eax = offset
                cl = @
                call mp1_poke
                remove this missile
                call mp1_notify_user
                }
        }
        m = m.next
    }
}

void mp1_missile_remove(m)
{ 

                edi = m.next
                using space to replace missle
                just put it in m.C ?
                No, just use another space to cover its location
                ecx = NEXT(edi)
                m.next = edi
                
                mp1_free(edi)
}

void update_base{
    decide which base to draw?
    andl    0x00ff0000, $base_alive, %eax

    if base1 is alive jmp draw life
    else draw dead 
    
    andl    0x0000ff00, $base_alive, %ebx
    andl    0x000000ff, $base_alive, %ecx

    drawlife
    {
        for (int ecx = 0; ecx < 5; ecx++)
        {
            eax = location_offset
            cl = 

        }
        
    }
    drawdead:
    for (int ecx = 0; ecx < 5; ecx++)
    {
        eax = locat
        
    }
    


    term by term 
}

void update_cross{

}