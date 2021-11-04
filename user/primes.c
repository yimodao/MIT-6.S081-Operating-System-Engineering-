#include "kernel/types.h"
#include "user/user.h"
#include "kernel/stat.h"
void dfs(int p[])
{int n,n2;
int number=0;
close(p[1]);
if(read(p[0],&n,4)==0)
    {
    close(p[0]);
    exit(0);
    }
int p2[2];
pipe(p2);
if(fork()==0)
    {
    dfs(p2);
    }
close(p2[0]);
while(read(p[0],&n2,4)!=0)
    {if(number==0)
        printf("prime %d\n",n2);
    if(n2%n)
        write(p2[1],&n2,4);
    number++;
    }
close(p[0]);
close(p2[1]);
wait(0);
exit(0);
}

int main(int argc,char*argv[])
{
if(argc>1)
    {
    fprintf(2,"usage:primes\n");
    exit(1);
    }
int p0[2];
pipe(p0);
if(fork()==0)
    dfs(p0);
close(p0[0]);
printf("prime %d\n",2);
for(int i=2;i<=35;i++)
    write(p0[1],&i,4);
close(p0[1]);
wait(0);
exit(0);
}