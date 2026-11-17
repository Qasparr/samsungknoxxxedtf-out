/*
 * ============================================================================
 * KNOX-LICENSE-ACTIVATOR — the one door the whole Knox seat hangs on
 * ----------------------------------------------------------------------------
 * "Do what thou wilt shall be the whole of the Law."
 *   Samsung's SDK does not wake for a stranger. Before any Knox API
 *   answers, the app presents its license key — the key the founder
 *   generates in his own Knox Partner Portal, Development while he
 *   tests, Commercial when he ships — and the Enterprise License
 *   Manager carries it to Samsung's entitlement service. This file
 *   is that presentation, and nothing else: the smallest file in the
 *   toolbox, standing at its gate.
 *
 * Authorship attributed exclusively to Johnathan "Qasparr" Monroe
 * (Greek, -ARR, All Rights Reserved, Without Prejudice).
 * XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
 * (2026 e.v.). Method of Science, Aim of Religion. 93.
 *
 * MECHANISM —
 *   activate(Context, key) calls the documented activation shape —
 *   EnterpriseLicenseManager.getInstance(context).activateLicense(key)
 *   — and reports the outcome as a line of record. Activation is
 *   asynchronous on the device (the entitlement verdict returns by
 *   broadcast), so this method reports "presented", never "granted":
 *   the grant is Samsung's server's word, and a wrapper that printed
 *   GRANTED for a presentation would be forging the very testimony
 *   this toolbox exists to read honestly.
 *   THE KEY IS AN INPUT. It is never stored in this repository, never
 *   logged, never printed — the report carries the key's LENGTH and
 *   nothing else, so the record can prove a key was presented
 *   without the record becoming the key's new hiding place.
 *
 * DOCTRINE — two named uncertainties, kept in the open:
 *   (1) THE IMPORT. Samsung has seated EnterpriseLicenseManager in
 *   more than one package across the SDK's generations; this file
 *   imports com.samsung.android.knox.EnterpriseLicenseManager, the
 *   Knox SDK 3.x seat beside EnterpriseDeviceManager. If the
 *   founder's seated JAR answers otherwise, the import — one line —
 *   is the whole correction, and the seat compile (build-wrappers.sh
 *   with the SDK present) is the witness that will say so.
 *   (2) THE GATE. Without the founder's Knox Partner Program
 *   enrollment there is no key and no JAR: this file is ACCOUNT-
 *   GATED at its root, and says so rather than apologising for it.
 * ============================================================================
 */

package com.qasparr.knoxbridge;

import android.content.Context;

import com.samsung.android.knox.EnterpriseLicenseManager;

public final class KnoxLicenseActivator {

    private KnoxLicenseActivator() {
    }

    /**
     * Present the founder's KPE license key to Samsung's entitlement
     * service. Reports presentation, never a grant.
     *
     * @param key the license key from the founder's Knox Partner
     *            Portal; used in the call, never stored or printed.
     * @return a line of record: key length + presentation outcome.
     */
    public static String activate(Context context, String key) {
        if (key == null || key.isEmpty()) {
            return "license : NOT PRESENTED — no key supplied "
                    + "(the key lives in the founder's Knox Partner Portal, "
                    + "never in this repository)";
        }
        try {
            EnterpriseLicenseManager elm =
                    EnterpriseLicenseManager.getInstance(context);
            if (elm == null) {
                return "license : NOT PRESENTED — EnterpriseLicenseManager "
                        + "does not stand on this device/build";
            }
            elm.activateLicense(key);
            return "license : PRESENTED (key length " + key.length()
                    + "; the grant is Samsung's server's word, "
                    + "returned asynchronously — not claimed here)";
        } catch (Exception e) {
            return "license : PRESENTATION REFUSED ("
                    + e.getClass().getSimpleName() + ")";
        }
    }
}

/*
 * ============================================================================
 * 93 — Live, Love, and let Love, Live.
 * ============================================================================
 */
