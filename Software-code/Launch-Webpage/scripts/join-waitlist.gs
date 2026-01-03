/**
 * Join waitlist (Web App) — upsert by email
 * - If email is NEW: append row + send "welcome" email
 * - If email EXISTS: append recommendation to that row + send "relax" email
 *
 * Assumes headers: Name | Email | Recommendation | LaunchEmailSentAt
 * (Recommendation can be empty; LaunchEmailSentAt is used by your launch sender script)
 */

const SHEET_NAME = "Slipstream-waitlist";

// --- WEB APP ENTRYPOINT ---
function doPost(e) {
  const lock = LockService.getScriptLock();
  try {
    lock.waitLock(10000);

    const params = (e && e.parameter) || {};
    const name = String(params.name || "").trim();
    const emailRaw = String(params.email || "").trim();
    const recommendation = String(params.recommendation || "").trim();

    if (!emailRaw) return json_({ success: false, error: "Email required" });

    const email = emailRaw.toLowerCase();
    if (!isValidEmail_(email)) return json_({ success: false, error: "Invalid email" });

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(SHEET_NAME) || ss.getSheets()[0];
    if (!sheet) return json_({ success: false, error: "Sheet not found" });

    const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0].map(String);
    const nameCol = headers.indexOf("Name") + 1;
    const emailCol = headers.indexOf("Email") + 1;
    const recCol = headers.indexOf("Recommendation") + 1;

    if (!emailCol) return json_({ success: false, error: "Email column not found (header must be 'Email')" });
    if (!recCol) return json_({ success: false, error: "Recommendation column not found (header must be 'Recommendation')" });

    const existingRow = findExistingEmailRow_(sheet, emailCol, email);

    if (existingRow) {
      // Update/append recommendation
      if (recommendation) {
        const cell = sheet.getRange(existingRow, recCol);
        const existingRec = String(cell.getValue() || "").trim();

        // Append with separator if there's already something there
        const updatedRec = existingRec
          ? (existingRec + " | " + recommendation)
          : recommendation;

        cell.setValue(updatedRec);
      }

      sendAlreadyOnWaitlistEmail_(name, email);
      return json_({ success: true, alreadyOnWaitlist: true });
    }

    // New signup: append row aligned to headers
    const row = new Array(sheet.getLastColumn()).fill("");
    if (nameCol) row[nameCol - 1] = name;
    row[emailCol - 1] = email;
    row[recCol - 1] = recommendation;

    sheet.appendRow(row);

    sendWaitlistWelcomeEmail_(name, email);
    return json_({ success: true, alreadyOnWaitlist: false });

  } catch (err) {
    console.error(err);
    return json_({ success: false, error: "Server error" });
  } finally {
    try { lock.releaseLock(); } catch (_) {}
  }
}

// --- EMAILS ---
function sendWaitlistWelcomeEmail_(name, email) {
  const subject = "You’re in ✅";
  const plainBody =
    `${name ? `Hi ${name},` : "Hi there,"}\n\n` +
    `Welcome to the Slipstream club — we’ll try to cook something good!!!\n` +
    `For now just wait a little bit 😄\n\n` +
    `See you on track,\n` +
    `The Slipstream Team`;

  GmailApp.sendEmail(email, subject, plainBody);
}

function sendAlreadyOnWaitlistEmail_(name, email) {
  const subject = "We got you 😄";
  const plainBody =
    `${name ? `Hi ${name},` : "Hi there,"}\n\n` +
    `Relax my guy, we are trying to finish fast but give us a chance 😄\n\n` +
    `See you on track,\n` +
    `The Slipstream Team`;

  GmailApp.sendEmail(email, subject, plainBody);
}

// --- HELPERS ---
function json_(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

function isValidEmail_(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function findExistingEmailRow_(sheet, emailCol, emailLower) {
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return null;

  const values = sheet.getRange(2, emailCol, lastRow - 1, 1).getValues();
  for (var i = 0; i < values.length; i++) {
    var v = String(values[i][0] || "").trim().toLowerCase();
    if (v === emailLower) return i + 2; // actual sheet row
  }
  return null;
}
