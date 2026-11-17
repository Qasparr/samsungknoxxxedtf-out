/*
 * ============================================================================
 * PLATFORM-POLICY-READER — the device-owner surface Android itself gives
 * ----------------------------------------------------------------------------
 * "Do what thou wilt shall be the whole of the Law."
 *   Before Samsung's kit is even opened, the platform already answers
 *   the first questions an owner asks of his own device: am I the
 *   Device Owner here? Is a profile mine? What does the build call
 *   itself? This reader asks exactly those, through documented
 *   Android APIs, and changes nothing. A reader that also writes is
 *   a policy engine wearing a reader's coat; this file refuses the
 *   disguise.
 *
 * Authorship attributed exclusively to Johnathan "Qasparr" Monroe
 * (Greek, -ARR, All Rights Reserved, Without Prejudice).
 * XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
 * (2026 e.v.). Method of Science, Aim of Religion. 93.
 *
 * MECHANISM —
 *   report(Context) assembles a plain-text dossier:
 *     - DevicePolicyManager.isDeviceOwnerApp(own package) and
 *       isProfileOwnerApp(own package): the platform's own verdicts,
 *       needing no admin activation and no license — a caller may
 *       always ask whether IT is the owner;
 *     - the Build identity fields (manufacturer, model, fingerprint,
 *       release): what the firmware calls itself;
 *     - the Knox version string, read REFLECTIVELY from
 *       android.os.SystemProperties (ro.build.version.knox). That
 *       class is not public API, so it is reached by reflection and
 *       every failure on that road is reported as "unreadable",
 *       never guessed. The reflective seat is labelled here so no
 *       reader mistakes it for a documented call.
 *   Every value is a read. There is no setter in this file.
 *
 * DOCTRINE —
 *   This file compiles against the stock android.jar — the toolbox
 *   test suite proves it on this host — and runs on any Android
 *   device, Knox or not. It is the floor of the Knox NDK toolbox:
 *   the part that works before the founder's Samsung seat is laid,
 *   so the toolbox is useful on day one and honest about which of
 *   its rooms are still locked.
 * ============================================================================
 */

package com.qasparr.knoxbridge;

import android.app.admin.DevicePolicyManager;
import android.content.Context;
import android.os.Build;

import java.lang.reflect.Method;

public final class PlatformPolicyReader {

    private PlatformPolicyReader() {
        // A reader is a door, not a house: no instances.
    }

    /** Reflective read of a system property; "" when the road fails. */
    private static String systemProperty(String key) {
        try {
            Class<?> sp = Class.forName("android.os.SystemProperties");
            Method get = sp.getMethod("get", String.class, String.class);
            Object value = get.invoke(null, key, "");
            return value == null ? "" : value.toString();
        } catch (Exception e) {
            return "";
        }
    }

    /**
     * The platform dossier. Plain text, one fact per line, so it can
     * be pasted into a record without a parser standing between the
     * reader and the fact.
     */
    public static String report(Context context) {
        StringBuilder out = new StringBuilder();
        String pkg = context.getPackageName();

        DevicePolicyManager dpm = (DevicePolicyManager)
                context.getSystemService(Context.DEVICE_POLICY_SERVICE);
        out.append("== platform policy readout ==\n");
        if (dpm == null) {
            out.append("devicePolicyManager : UNAVAILABLE on this device\n");
        } else {
            out.append("deviceOwner(own pkg)   : ")
               .append(dpm.isDeviceOwnerApp(pkg)).append('\n');
            out.append("profileOwner(own pkg)  : ")
               .append(dpm.isProfileOwnerApp(pkg)).append('\n');
        }

        out.append("manufacturer           : ").append(Build.MANUFACTURER).append('\n');
        out.append("model                  : ").append(Build.MODEL).append('\n');
        out.append("board                  : ").append(Build.BOARD).append('\n');
        out.append("android release        : ").append(Build.VERSION.RELEASE).append('\n');
        out.append("fingerprint            : ").append(Build.FINGERPRINT).append('\n');

        String knox = systemProperty("ro.build.version.knox");
        out.append("knox version (reflective read) : ")
           .append(knox.isEmpty() ? "unreadable" : knox).append('\n');
        return out.toString();
    }
}

/*
 * ============================================================================
 * 93 — Live, Love, and let Love, Live.
 * ============================================================================
 */
