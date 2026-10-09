#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <math.h>

static NSString *const BarBundleIdentifier = @"com.bar.app";
static NSString *const HiddenItemPositionKey = @"NSStatusItem Preferred Position HItem";
static const double BuiltInDisplayPosition = 720.0;
static const double ExternalDisplayPosition = 100000.0;

static void RunTask(NSString *launchPath, NSArray<NSString *> *arguments)
{
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:launchPath];
    task.arguments = arguments;
    task.standardOutput = [NSFileHandle fileHandleWithNullDevice];
    task.standardError = [NSFileHandle fileHandleWithNullDevice];

    NSError *error = nil;
    if ([task launchAndReturnError:&error]) {
        [task waitUntilExit];
    } else {
        NSLog(@"Unable to run %@: %@", launchPath, error.localizedDescription);
    }
}

static void ApplyLayoutForPrimaryDisplay(void)
{
    CGDirectDisplayID mainDisplay = CGMainDisplayID();
    BOOL isExternal = !CGDisplayIsBuiltin(mainDisplay);
    double desiredPosition = isExternal ? ExternalDisplayPosition : BuiltInDisplayPosition;

    CFPropertyListRef storedValue = CFPreferencesCopyAppValue(
        (__bridge CFStringRef)HiddenItemPositionKey,
        (__bridge CFStringRef)BarBundleIdentifier
    );
    NSNumber *currentPosition = CFBridgingRelease(storedValue);

    if (currentPosition != nil && fabs(currentPosition.doubleValue - desiredPosition) < 0.5) {
        return;
    }

    // Quit first so bar cannot overwrite the new divider position while exiting.
    RunTask(@"/usr/bin/pkill", @[@"-x", @"bar"]);
    [NSThread sleepForTimeInterval:0.3];

    CFPreferencesSetAppValue(
        (__bridge CFStringRef)HiddenItemPositionKey,
        (__bridge CFNumberRef)@(desiredPosition),
        (__bridge CFStringRef)BarBundleIdentifier
    );
    CFPreferencesAppSynchronize((__bridge CFStringRef)BarBundleIdentifier);

    RunTask(@"/usr/bin/open", @[@"-a", @"/Applications/bar.app"]);
    NSLog(
        @"Applied %@ display layout (divider %.0f)",
        isExternal ? @"external" : @"built-in",
        desiredPosition
    );
}

static void DisplayConfigurationChanged(
    CGDirectDisplayID display,
    CGDisplayChangeSummaryFlags flags,
    void *userInfo
)
{
    (void)display;
    (void)flags;
    (void)userInfo;

    // Display metadata can settle shortly after the reconfiguration callback.
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            ApplyLayoutForPrimaryDisplay();
        }
    );
}

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    @autoreleasepool {
        ApplyLayoutForPrimaryDisplay();
        CGDisplayRegisterReconfigurationCallback(DisplayConfigurationChanged, NULL);
        [[NSRunLoop mainRunLoop] run];
        CGDisplayRemoveReconfigurationCallback(DisplayConfigurationChanged, NULL);
    }

    return 0;
}
