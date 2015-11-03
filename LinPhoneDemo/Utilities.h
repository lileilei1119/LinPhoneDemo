//工具类

#define MY_NAME         @"111"
#define OUR_DOMAIN      @"192.168.1.147"
#define OUR_PORT        @"5060"
#define YOU_NAME        @"110"

//#define SHOW_PHONE_LOG

#ifdef SHOW_PHONE_LOG
    #define PLog(...);    NSLog(__VA_ARGS__);
#else
    #define PLog(...);    // NSLog(__VA_ARGS__);
#endif


#define HAVE_X264

