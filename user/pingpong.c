#include "kernel/types.h"
#include "user/user.h"
#include "kernel/stat.h"

int main(int argc,char* argv[])
{
if(argc!=1)
    {
    fprintf(2,"usage:pingpong\n");
    exit(1);
    }
char buff[1];
int p1[2];
int p2[2];
pipe(p1);
pipe(p2);
if(fork()==0)
    {close(p1[1]);
    close(p2[0]);
    if(read(p1[0],buff,sizeof(buff))==1)
        {close(p1[0]);
        printf("%d: received ping\n",getpid());
        }
    write(p2[1],"p",1);
    close(p2[1]);
    exit(0);
    }
close(p1[0]);
close(p2[1]);
write(p1[1],"p",1);
close(p1[1]);
if(read(p2[0],buff,sizeof(buff))==1)
    {
    close(p2[0]);
    printf("%d: received pong\n",getpid());
    }
wait(0);
exit(0);
}
