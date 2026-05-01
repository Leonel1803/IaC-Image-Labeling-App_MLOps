const apiBase = (window.APP_CONFIG && window.APP_CONFIG.API_BASE_URL || "").replace(/\/$/, "");

const fileInput = document.getElementById("fileInput");
const uploadBtn = document.getElementById("uploadBtn");
const uploadStatus = document.getElementById("uploadStatus");
const labelInput = document.getElementById("labelInput");
const searchBtn = document.getElementById("searchBtn");
const searchStatus = document.getElementById("searchStatus");
const results = document.getElementById("results");

function setStatus(element, text, isError = false) {
  element.textContent = text;
  element.style.color = isError ? "#f15c5c" : "#9fb0cb";
}

async function createUploadUrl(file) {
  const query = new URLSearchParams({
    filename: file.name || "image.jpg",
    contentType: file.type || "application/octet-stream"
  });
  const response = await fetch(`${apiBase}/upload-url?${query.toString()}`, {
    method: "GET"
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Could not create upload URL (${response.status}): ${errorText}`);
  }

  return response.json();
}

async function uploadFile(file, uploadUrl) {
  const response = await fetch(uploadUrl, {
    method: "PUT",
    headers: { "Content-Type": file.type || "application/octet-stream" },
    body: file
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Upload failed (${response.status}): ${errorText}`);
  }
}

function renderResults(items) {
  results.innerHTML = "";
  for (const item of items) {
    const card = document.createElement("article");
    card.className = "result-item";
    card.innerHTML = `
      <img src="${item.viewUrl}" alt="${item.imageId}" />
      <h3>${item.imageId}</h3>
      <small>${(item.labels || []).join(", ")}</small>
    `;
    results.appendChild(card);
  }
}

uploadBtn.addEventListener("click", async () => {
  try {
    if (!apiBase.includes("https://")) {
      throw new Error("Set API_BASE_URL in web/config.js");
    }
    const file = fileInput.files[0];
    if (!file) {
      throw new Error("Select an image first");
    }

    setStatus(uploadStatus, "Creating upload URL...");
    const payload = await createUploadUrl(file);

    setStatus(uploadStatus, "Uploading to S3...");
    await uploadFile(file, payload.uploadUrl);

    setStatus(uploadStatus, `Uploaded: ${payload.key}. Wait a few seconds for labeling.`);
  } catch (error) {
    setStatus(uploadStatus, error.message, true);
  }
});

searchBtn.addEventListener("click", async () => {
  try {
    if (!apiBase.includes("https://")) {
      throw new Error("Set API_BASE_URL in web/config.js");
    }
    const label = labelInput.value.trim();
    if (!label) {
      throw new Error("Write a label to search");
    }

    setStatus(searchStatus, "Searching...");
    const response = await fetch(`${apiBase}/search?label=${encodeURIComponent(label)}`);
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Search failed (${response.status}): ${errorText}`);
    }

    const data = await response.json();
    renderResults(data.items || []);
    setStatus(searchStatus, `Found ${data.count || 0} image(s).`);
  } catch (error) {
    setStatus(searchStatus, error.message, true);
  }
});
