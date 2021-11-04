#include "kernel/types.h"
#include "kernel/fcntl.h"
#include "kernel/stat.h"
#include "kernel/fs.h"
#include "user/user.h"
char* fmt_name(char *path){
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--);
  p++;
  memmove(buf, p, strlen(p)+1);
  return buf;
}

void search(char*path,char*filename)
{
char buf[512],*p;
struct dirent de;
int fd;
struct stat st;
if((fd=open(path,0))<0){
    fprintf(2,"ls:cannot open %s\n",path);
    return;
}
if(fstat(fd,&st)<0){
    fprintf(2,"ls:cannot stat %s\n",path);
    close(fd);
    return;
}
switch(st.type){
case T_FILE:
    if(strcmp(filename,fmt_name(path))==0)
        {printf("%s\n",path);
        }
    break;
case T_DIR:
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
      printf("ls: path too long\n");
      break;
    }
    strcpy(buf,path);
    p=buf+strlen(buf);
    *p++='/';
    while(read(fd,&de,sizeof(de))==sizeof(de)){
        if(de.inum == 0 || de.inum == 1 || strcmp(de.name, ".")==0 || strcmp(de.name, "..")==0)
            continue;
        memmove(p, de.name, strlen(de.name));
        p[strlen(de.name)] = 0;
        search(buf,filename);   
    }
    break;
}
close(fd);
}

int main(int argc,char* argv[])
{if(argc!=3)
    {
    fprintf(2,"usage:find director filename\n");
    exit(1);
    }
search(argv[1],argv[2]);
exit(0);
}