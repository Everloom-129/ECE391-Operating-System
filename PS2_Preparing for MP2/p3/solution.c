// You may add up to 3 elements to this struct.
// The type of synchronization primitive you may use is SpinLock.
typedef struct biscuit_juice_lock
{
    unsigned long juice_counter;   // has a limit of 4
    unsigned long biscuit_counter; // has no limit (inifite)
    spinlock_t *fd_spinlock;       // spinlock
} fd_lock_t;

void produce_biscuit(fd_lock_t *fd)
{
    // because the max value of unsigned long is 4294967295(2^32-1) and the number of
    // biscuit cannot be negative, therefore there is a restriction of the number of bisuit.
    // the number of biscuit should <= 4294967295(2^32-1)
    unsigned long flags;
    spin_lock_irqsave(fd->fd_spinlock, flags);
    fd->biscuit_counter++;
    spin_lock_irqrestore(fd->fd_spinlock, flags);
}

void consume_biscuit(fd_lock_t *fd)
{
    unsigned long flags;
    while (1)// We use if statement twice to ensure the function satisfy the constrain, 
    {        // and speed up the program
        if (fd->juice_counter == 0 && fd->biscuit_counter > 0)
        {
            spin_lock_irqsave(fd->fd_spinlock, flags);
            if (fd->juice_counter == 0 && fd->biscuit_counter > 0)
            {
                fd->biscuit_counter--;
                spin_lock_irqrestore(fd->fd_spinlock, flags);
                return;
            }
            spin_lock_irqrestore(fd->fd_spinlock, flags);
        }
    }
}

int produce_juice(fd_lock_t *fd)
{
    unsigned long flags;
    if (fd->juice_counter == 4)
    {
        return -1;
    }
    spin_lock_irqsave(fd->fd_spinlock, flags);
    fd->juice_counter++;
    spin_lock_irqrestore(fd->fd_spinlock, flags);
    return 0;
}

void consume_juice(fd_lock_t *fd)
{
    unsigned long flags;
        while (1)// We use if statement twice to ensure the function satisfy the constrain, 
        {        // and speed up the program
            if (fd->juice_counter > 0)  //The first condition is to speed up 
            {
                spin_lock_irqsave(fd->fd_spinlock, flags);
                if (fd->juice_counter > 0)  // Here we 
                {
                    fd->juice_counter--;
                    spin_lock_irqrestore(fd->fd_spinlock, flags);
                    return;
                }
                spin_lock_irqrestore(fd->fd_spinlock, flags);
            }
    }
}
/* One possible Main program initialization design

int main(int argc, char const *argv[])
{
    fd_lock_t PIG_MACHINE;
    PIG_MACHINE.biscuit_counter = 0;
    PIG_MACHINE.juice_counter = 0;

    spin_lock_init(PIG_MACHINE.fd_spinlock);

    return 0;
}

Question to TA: How to write a parrellel test program?
*/

