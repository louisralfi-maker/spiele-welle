// Read-only: prints CPU temperature keys and fan speeds from the Intel SMC. Writes nothing.
#include <IOKit/IOKitLib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
typedef struct { char major, minor, build, reserved[1]; UInt16 release; } V;
typedef struct { UInt16 version, length; UInt32 cpuPLimit, gpuPLimit, memPLimit; } L;
typedef struct { UInt32 dataSize, dataType; char dataAttributes; } K;
typedef struct { UInt32 key; V vers; L pLimitData; K keyInfo; char result, status, data8; UInt32 data32; char bytes[32]; } D;
static io_connect_t c;
static UInt32 s2u(const char *s){UInt32 t=0;for(int i=0;i<4;i++)t=(t<<8)|(unsigned char)s[i];return t;}
static int call(D*in,D*out){size_t a=sizeof(D),b=sizeof(D);return IOConnectCallStructMethod(c,2,in,a,out,&b);}
static int rd(const char*key,D*out){D in;memset(&in,0,sizeof in);memset(out,0,sizeof *out);in.key=s2u(key);in.data8=9;
 if(call(&in,out))return -1;UInt32 sz=out->keyInfo.dataSize,ty=out->keyInfo.dataType;if(sz==0)return -1;
 memset(&in,0,sizeof in);in.key=s2u(key);in.keyInfo.dataSize=sz;in.data8=5;D o2;memset(&o2,0,sizeof o2);if(call(&in,&o2))return -1;
 o2.keyInfo.dataSize=sz;o2.keyInfo.dataType=ty;*out=o2;return 0;}
static double val(D*d){char t[5];UInt32 ty=d->keyInfo.dataType;t[0]=ty>>24;t[1]=ty>>16;t[2]=ty>>8;t[3]=ty;t[4]=0;unsigned char*b=(unsigned char*)d->bytes;
 if(!strcmp(t,"sp78"))return (double)(short)((b[0]<<8)|b[1])/256.0;
 if(!strcmp(t,"fpe2"))return ((b[0]<<8)|b[1])/4.0;
 if(!strcmp(t,"flt ")){float f;memcpy(&f,b,4);return f;}
 if(!strcmp(t,"ui8 "))return b[0];
 if(!strcmp(t,"ui16"))return (b[0]<<8)|b[1];
 return -999;}
int main(int ac,char**av){io_service_t s=IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("AppleSMC"));if(!s){puts("no smc");return 1;}
 if(IOServiceOpen(s,mach_task_self(),0,&c)){puts("open failed");return 1;}
 const char*temps[]={"TC0P","TC0E","TC0F","TC0D","TCXC","TC1C","TC2C","TCGC","TB0T","TB1T","Ts0P","TH0a"};
 D d;for(unsigned i=0;i<sizeof temps/sizeof *temps;i++)if(!rd(temps[i],&d)){double v=val(&d);if(v>0&&v<130)printf("%s=%.1f ",temps[i],v);}
 if(!rd("FNum",&d))printf("fans=%.0f ",val(&d));
 const char*f[]={"F0Ac","F0Tg","F0Mn","F0Mx","F0Md","FS! "};for(int i=0;i<6;i++)if(!rd(f[i],&d)){double v=val(&d);if(v>=0)printf("%s=%.0f ",f[i],v);}
 puts("");IOServiceClose(c);return 0;}
