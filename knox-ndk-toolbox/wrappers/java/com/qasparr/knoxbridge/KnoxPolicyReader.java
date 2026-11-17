/*
 * ============================================================================
 * KNOX-POLICY-READER — Samsung's own policy surface, read as published
 * ----------------------------------------------------------------------------
 * "Do what thou wilt shall be the whole of the Law."
 *   Where the platform reader asks Android's questions, this reader
 *   asks Samsung's: what Knox API level does this device speak, and
 *   does its inventory call it secure? The calls are Samsung's own,
 *   in Samsung's own shapes, taken from the Knox SDK API reference —
 *   EnterpriseDeviceManager.getInstance(Context) (the documented
 *   door since Knox API level 24), getApiLevel(), and the
 *   DeviceInventory policy reached through it. Nothing is set,
 *   toggled, or enforced here: the toolbox administers by first
 *   knowing, and knowing is a read.
 *
 * Authorship attributed exclusively to Johnathan "Qasparr" Monroe
 * (Greek, -ARR, All Rights Reserved, Without Prejudice).
 * XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
 * (2026 e.v.). Method of Science, Aim of Religion. 93.
 *
 * MECHANISM —
 *   report(Context) asks, in order:
 *     1. EnterpriseDeviceManager.getInstance(context) — null is a
 *        possible and reportable answer (pre-API-24 Knox, or a
 *        device where the service does not stand); the report says
 *        so instead of dying on the doorstep.
 *     2. edm.getApiLevel() — the Knox API level the device speaks;
 *        the same number Settings shows under the Knox version.
 *     3. edm.getDeviceInventory().isDeviceSecure() — Samsung's own
 *        inventory verdict on whether a lock credential stands.
 *   Each call is wrapped: Knox policy calls throw SecurityException
 *   when the caller lacks the Knox permission or an active admin
 *   seat, and a reader's duty is to report the refusal as a fact
 *   ("REFUSED: SecurityException — permission/admin seat missing"),
 *   not to crash in front of the founder. Inventory reads ride the
 *   permission com.samsung.android.knox.permission.KNOX_INVENTORY,
 *   whose protection level is signature — the report names it so
 *   the refusal, when it comes, arrives pre-explained.
 *
 * DOCTRINE — SEAT-GATED, and the gate is named:
 *   This file imports com.samsung.android.knox.* — Samsung's
 *   classes, from Samsung's JAR. It compiles only when the Knox SDK
 *   stands in the toolbox's seat (see ../../sdk-seat/), which
 *   arrives only through the founder's Knox Partner Program door.
 *   The toolbox test suite therefore does not compile this file on
 *   this host; it verifies the gate instead, and prints GATED. A
 *   version of this file that "compiled" by stubbing Samsung's
 *   classes would be a forgery of exactly the kind this toolbox
 *   exists to refuse.
 * ============================================================================
 */

package com.qasparr.knoxbridge;

import android.content.Context;

import com.samsung.android.knox.EnterpriseDeviceManager;
import com.samsung.android.knox.deviceinfo.DeviceInventory;

public final class KnoxPolicyReader {

    private KnoxPolicyReader() {
    }

    /** The Knox dossier: API level + the inventory's security verdict. */
    public static String report(Context context) {
        StringBuilder out = new StringBuilder();
        out.append("== knox policy readout ==\n");

        EnterpriseDeviceManager edm;
        try {
            edm = EnterpriseDeviceManager.getInstance(context);
        } catch (Exception e) {
            out.append("enterpriseDeviceManager : REFUSED (")
               .append(e.getClass().getSimpleName()).append(")\n");
            return out.toString();
        }
        if (edm == null) {
            out.append("enterpriseDeviceManager : NULL — the Knox policy "
                    + "service does not stand on this device/build\n");
            return out.toString();
        }

        try {
            out.append("knox api level : ").append(edm.getApiLevel()).append('\n');
        } catch (SecurityException e) {
            out.append("knox api level : REFUSED (SecurityException — "
                    + "license/admin seat missing)\n");
        }

        try {
            DeviceInventory inventory = edm.getDeviceInventory();
            if (inventory == null) {
                out.append("device secure  : UNREADABLE (inventory policy null)\n");
            } else {
                out.append("device secure  : ")
                   .append(inventory.isDeviceSecure())
                   .append(" (DeviceInventory; rides KNOX_INVENTORY, "
                           + "signature-level)\n");
            }
        } catch (SecurityException e) {
            out.append("device secure  : REFUSED (SecurityException — "
                    + "KNOX_INVENTORY or admin seat missing)\n");
        }
        return out.toString();
    }
}

/*
 * ============================================================================
 * 93 — Live, Love, and let Love, Live.
 * ============================================================================
 */
