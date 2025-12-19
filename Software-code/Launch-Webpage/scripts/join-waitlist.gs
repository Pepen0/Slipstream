function doPost(e) {
  try {
    // Handle form data (URLSearchParams)
    const name = e.parameter.name || "";
    const email = e.parameter.email || "";
    const recommendation = e.parameter.recommendation || "";

    if (!email) {
      return ContentService
        .createTextOutput(JSON.stringify({ success: false, error: "Email required" }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
    sheet.appendRow([name, email, recommendation]);

    return ContentService
      .createTextOutput(JSON.stringify({ success: true }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ success: false, error: "Server error" }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}