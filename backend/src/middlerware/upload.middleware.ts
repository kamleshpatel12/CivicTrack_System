import multer from "multer";

// Local file storage (no longer used, kept for compatibility)
const storage = multer.memoryStorage();

export const upload = multer({ storage });
