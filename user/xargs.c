#include "kernel/types.h"
#include "user/user.h"
#include "kernel/stat.h"
int main(int argc,char* argv[])
{char block[125];
char buf[24];
char*p=buf;
char*newargv[24];
int j=0;
int k;
int l,m=0;
for(int i=1;i<argc;i++)
    newargv[j++]=argv[i];
while((k=read(0,block,sizeof(block)))>0)
    {for(l=0;l<k;l++)
        {if(block[l]=='\n')
            {buf[m]=0;
            m=0;
            newargv[j++]=p;
            newargv[j]=0;
            p=buf;
            j=argc-1;
            if(fork()==0)
                exec(newargv[0],newargv);
            wait(0);
            }
        else if(block[l]==' ')
            {
            buf[m++]=0;
            newargv[j++]=p;
            p=&buf[m];
            }
        else
            {
            buf[m++]=block[l];
            }
        }
    }
    exit(0);
}