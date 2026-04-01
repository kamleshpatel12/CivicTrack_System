import pool from "../config/database";

// Execute query and get results
export const query = async (sql: string, values?: any[]) => {
  try {
    const connection = await pool.getConnection();
    const [results] = await connection.execute(sql, values || []);
    connection.release();
    return results;
  } catch (error) {
    console.error("Database query error:", error);
    throw error;
  }
};

// Execute query with connection (for transactions)
export const queryWithConnection = async (
  connection: any,
  sql: string,
  values?: any[]
) => {
  return await connection.execute(sql, values || []);
};

// Get single row
export const queryOne = async (sql: string, values?: any[]) => {
  const results = await query(sql, values);
  return (results as any[])[0] || null;
};

// Get all rows
export const queryAll = async (sql: string, values?: any[]) => {
  return await query(sql, values);
};

// Insert and get ID
export const insert = async (sql: string, values?: any[]) => {
  const results = (await query(sql, values)) as any;
  return results.insertId;
};
