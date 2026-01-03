// REQUIRED: paste your Google Sheet ID here (from the sheet URL)
const SPREADSHEET_ID = "1AD6yfmyExQzjHP86kyFkhxm7alXP0kuXUaKmBH6ts98";

// Column headers we care about (we'll find by normalization; can auto-add if missing)
const COL_NAME = "Name";
const COL_EMAIL = "Email";
const COL_RECOMMENDATION = "Recommendation (Optional)";
const COL_SOURCE = "Source";
const COL_CREATED_AT = "CreatedAt";
const COL_UPDATED_AT = "UpdatedAt";

function doPost(e) {
  const lock = LockService.getScriptLock();
  try {
    lock.waitLock(10000);

    const params = parseParams_(e);

    const name = String(params.name || params.Name || "").trim();
    const emailRaw = String(params.email || params.Email || "").trim();

    // Accept both spellings + a couple common variants
    const recommendation = String(
      params.recommendation ||
        params.recommandation ||
        params.Recommendation ||
        params.Recommandation ||
        params["Recommandation (Optional)"] ||
        params["Recommendation (Optional)"] ||
        ""
    ).trim();

    const source = String(params.source || params.Source || "").trim();

    if (!emailRaw) return json_({ success: false, error: "Email required" });

    const email = emailRaw.toLowerCase();
    if (!isValidEmail_(email)) return json_({ success: false, error: "Invalid email" });

    const ss = SpreadsheetApp.openById(SPREADSHEET_ID);
    const sheet = ss.getSheetByName(SHEET_NAME) || ss.getSheets()[0];
    if (!sheet) return json_({ success: false, error: "Sheet not found" });

    // Ensure header row exists
    ensureHeaderRow_(sheet);

    // Ensure columns exist (adds them if missing)
    const colMap = ensureColumns_(sheet, [
      COL_NAME,
      COL_EMAIL,
      COL_RECOMMENDATION,
      COL_SOURCE,
      COL_CREATED_AT,
      COL_UPDATED_AT,
    ]);

    const emailCol = colMap[normalizeHeader_(COL_EMAIL)];
    if (!emailCol) return json_({ success: false, error: "Email column not found" });

    const existingRow = findExistingEmailRow_(sheet, emailCol, email);
    const nowIso = new Date().toISOString();

    if (existingRow) {
      // Update recommendation (append), source (overwrite if provided), updatedAt
      const recCol = colMap[normalizeHeader_(COL_RECOMMENDATION)];
      if (recCol && recommendation) {
        const cell = sheet.getRange(existingRow, recCol);
        const existingRec = String(cell.getValue() || "").trim();
        const updatedRec = existingRec ? `${existingRec} | ${recommendation}` : recommendation;
        cell.setValue(updatedRec);
      }

      const sourceCol = colMap[normalizeHeader_(COL_SOURCE)];
      if (sourceCol && source) sheet.getRange(existingRow, sourceCol).setValue(source);

      const updatedAtCol = colMap[normalizeHeader_(COL_UPDATED_AT)];
      if (updatedAtCol) sheet.getRange(existingRow, updatedAtCol).setValue(nowIso);

      sendAlreadyOnWaitlistEmail_(name, email);
      return json_({ success: true, alreadyOnWaitlist: true });
    }

    // New signup: append row aligned to current headers
    const lastCol = sheet.getLastColumn();
    const row = new Array(lastCol).fill("");

    const nameCol = colMap[normalizeHeader_(COL_NAME)];
    const recCol = colMap[normalizeHeader_(COL_RECOMMENDATION)];
    const sourceCol = colMap[normalizeHeader_(COL_SOURCE)];
    const createdAtCol = colMap[normalizeHeader_(COL_CREATED_AT)];
    const updatedAtCol = colMap[normalizeHeader_(COL_UPDATED_AT)];

    if (nameCol) row[nameCol - 1] = name;
    row[emailCol - 1] = email;
    if (recCol) row[recCol - 1] = recommendation;
    if (sourceCol) row[sourceCol - 1] = source;
    if (createdAtCol) row[createdAtCol - 1] = nowIso;
    if (updatedAtCol) row[updatedAtCol - 1] = nowIso;

    sheet.appendRow(row);

    sendWaitlistWelcomeEmail_(name, email);
    return json_({ success: true, alreadyOnWaitlist: false });
  } catch (err) {
    console.error(err);
    // If you want the real error in responses during debugging, temporarily return err.message.
    return json_({ success: false, error: "Server error" });
  } finally {
    try {
      lock.releaseLock();
    } catch (_) {}
  }
}

// Optional: simple GET health check
function doGet() {
  return json_({ ok: true });
}

// --- EMAILS ---

function sendWaitlistWelcomeEmail_(name, email) {
  const subject = "You’re in ✅";

  const plainBody =
    (name ? `Hi ${name},` : "Hi there,") + "\n\n" +
    "Welcome to the Slipstream club — we’ll try to cook something good!!!\n" +
    "For now just wait a little bit ┐(￣▽￣)┌\n\n" +
    "See you on track,\n" +
    "The Slipstream Team";

  const greeting = name ? `Hi ${escapeHtml_(name)},` : "Hi there,";
  const htmlBody =
    `${greeting}<br><br>` +
    `Welcome to the Slipstream club — we’ll try to cook something good!!!<br>` +
    `For now just wait a little bit ┐(￣▽￣)┌ <br><br>` +
    `See you on track,<br>` +
    `The Slipstream Team` +
    emailFooterHtml_();

  sendEmail_(email, subject, plainBody, htmlBody);
}

function sendAlreadyOnWaitlistEmail_(name, email) {
  const subject = "We got you ";

  const plainBody =
    (name ? `Hi ${name},` : "Hi there,") + "\n\n" +
    "Relax my guy, we are trying to finish fast but give us a chance ง'̀-'́)ง\n\n" +
    "See you on track,\n" +
    "The Slipstream Team";

  const greeting = name ? `Hi ${escapeHtml_(name)},` : "Hi there,";
  const htmlBody =
    `${greeting}<br><br>` +
    `Relax my guy, we are trying to finish fast but give us a chance ง'̀-'́)ง<br><br>` +
    `See you on track,<br>` +
    `The Slipstream Team` +
    emailFooterHtml_();

  sendEmail_(email, subject, plainBody, htmlBody);
}

// --- HELPERS ---
function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(
    ContentService.MimeType.JSON
  );
}

function isValidEmail_(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// Robust param parsing: supports URLSearchParams (x-www-form-urlencoded) and JSON
function parseParams_(e) {
  const out = Object.assign({}, (e && e.parameter) || {});
  const postData = e && e.postData;

  if (!postData || !postData.contents) return out;

  const ct = String(postData.type || "").toLowerCase();
  const body = String(postData.contents || "");

  // JSON
  if (ct.indexOf("application/json") !== -1) {
    try {
      const parsed = JSON.parse(body);
      if (parsed && typeof parsed === "object") {
        for (const k in parsed) out[k] = parsed[k];
      }
    } catch (_) {}
    return out;
  }

  // x-www-form-urlencoded (sometimes Apps Script already puts these into e.parameter,
  // but we parse anyway as a fallback)
  if (
    ct.indexOf("application/x-www-form-urlencoded") !== -1 ||
    ct.indexOf("text/plain") !== -1
  ) {
    const pairs = body.split("&");
    for (const p of pairs) {
      const idx = p.indexOf("=");
      if (idx === -1) continue;
      const k = decodeURIComponent(p.slice(0, idx).replace(/\+/g, " "));
      const v = decodeURIComponent(p.slice(idx + 1).replace(/\+/g, " "));
      if (!(k in out)) out[k] = v;
    }
  }

  return out;
}

// Normalize headers like: "Name," or "Recommendation (Optional)" -> "name" / "recommendationoptional"
function normalizeHeader_(v) {
  return String(v || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z]/g, "");
}

function ensureHeaderRow_(sheet) {
  const lastRow = sheet.getLastRow();
  const lastCol = sheet.getLastColumn();
  if (lastRow === 0 || lastCol === 0) {
    sheet.getRange(1, 1, 1, 1).setValue("Email");
  }
}

// Ensures each header exists; returns a map { normalizedHeader: colIndex }
function ensureColumns_(sheet, desiredHeaders) {
  const lastCol = Math.max(sheet.getLastColumn(), 1);
  const rawHeaders = sheet.getRange(1, 1, 1, lastCol).getValues()[0];
  const headersNorm = rawHeaders.map((h) => normalizeHeader_(h));

  // Build initial map
  const map = {};
  for (let i = 0; i < headersNorm.length; i++) {
    if (headersNorm[i]) map[headersNorm[i]] = i + 1; // 1-based
  }

  // Add missing desired headers
  for (const header of desiredHeaders) {
    const key = normalizeHeader_(header);
    if (!key) continue;
    if (map[key]) continue;

    const newCol = sheet.getLastColumn() + 1;
    sheet.getRange(1, newCol).setValue(header);
    map[key] = newCol;
  }

  return map;
}

function findExistingEmailRow_(sheet, emailCol, emailLower) {
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return null;

  const values = sheet.getRange(2, emailCol, lastRow - 1, 1).getValues();
  for (var i = 0; i < values.length; i++) {
    var v = String(values[i][0] || "").trim().toLowerCase();
    if (v === emailLower) return i + 2;
  }
  return null;
}

// --- shared helpers ---

function sendEmail_(to, subject, plainBody, htmlBody) {
  // subject must be plain text; keep emoji, strip any tags if ever added
  const subjectPlain = String(subject).replace(/<[^>]*>?/gm, "");
  GmailApp.sendEmail(to, subjectPlain, plainBody || "", { htmlBody: htmlBody });
}

function emailFooterHtml_() {
  // Copied from your launch-email.gs footer (logo + links) :contentReference[oaicite:1]{index=1}
  return `
    <br><br>
    <hr style="border:none;border-top:1px solid #444;">
    <div style="text-align:center;font-size:12px;color:#666;">
      <img src="https://slipstream-3gw.pages.dev/logo-slipstream.png"
          alt="Slipstream Logo"
          width="140"
          style="margin-bottom:10px;">
      <br>
      <a href="https://www.instagram.com/slipstrearn"
        style="margin-right:12px;color:#e63946;text-decoration:none;font-weight:bold;">
        Instagram
      </a>
      <a href="https://www.youtube.com/channel/UCHCf9AAipaBe-YrR8mLdMkw"
        style="color:#e63946;text-decoration:none;font-weight:bold;">
        YouTube
      </a>
      <br><br>
      © Slipstream 2025 — Montreal, QC
    </div>`;
}

function escapeHtml_(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  }[c]));
}
