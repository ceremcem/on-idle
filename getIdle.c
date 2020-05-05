#include <X11/extensions/scrnsaver.h>
#include <stdio.h>

int main(void) {
    Display *dpy = XOpenDisplay(NULL);

    if (!dpy) {
        return(1);
    }

    XScreenSaverInfo *info = XScreenSaverAllocInfo();
    XScreenSaverQueryInfo(dpy, DefaultRootWindow(dpy), info);
    printf("%u\n", info->idle);

      return(0);
}
