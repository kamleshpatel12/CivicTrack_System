"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.insert = exports.queryAll = exports.queryOne = exports.queryWithConnection = exports.query = void 0;
const database_1 = __importDefault(require("../config/database"));
// Execute query and get results
const query = (sql, values) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const connection = yield database_1.default.getConnection();
        const [results] = yield connection.execute(sql, values || []);
        connection.release();
        return results;
    }
    catch (error) {
        console.error("Database query error:", error);
        throw error;
    }
});
exports.query = query;
// Execute query with connection (for transactions)
const queryWithConnection = (connection, sql, values) => __awaiter(void 0, void 0, void 0, function* () {
    return yield connection.execute(sql, values || []);
});
exports.queryWithConnection = queryWithConnection;
// Get single row
const queryOne = (sql, values) => __awaiter(void 0, void 0, void 0, function* () {
    const results = yield (0, exports.query)(sql, values);
    return results[0] || null;
});
exports.queryOne = queryOne;
// Get all rows
const queryAll = (sql, values) => __awaiter(void 0, void 0, void 0, function* () {
    return yield (0, exports.query)(sql, values);
});
exports.queryAll = queryAll;
// Insert and get ID
const insert = (sql, values) => __awaiter(void 0, void 0, void 0, function* () {
    const results = (yield (0, exports.query)(sql, values));
    return results.insertId;
});
exports.insert = insert;
