import {Response} from 'express';
import date from "date-and-time";
import {DATABASE_DATE_FORMAT} from "./firebase/util";

export function ResponseError(res: Response, error: string, status: number) {
    res.status(status);
    res.json({
        success: false,
        error: {
            message: error,
            code: status
        }
    });
    console.error(`[RESPONSE ERROR]: METHOD: ${res.req.method}, IP: ${res.req.ip}, URL: ${res.req.url}, ERROR: ${error}`);
}

export function ResponseSuccess(res: Response, data: object) {
    res.status(200);
    res.setHeader('Cache-Control', 'no-cache');
    res.json({
        success: true,
        data
    });
    console.log(`[RESPONSE SUCCESS]: METHOD: ${res.req.method}, IP: ${res.req.ip}, URL: ${res.req.url}, DATA: ${JSON.stringify(data)}`);
}

export function GetDateFromStr(YYYYMMDD: string): number {
    return parseInt(date.format(new Date(YYYYMMDD), DATABASE_DATE_FORMAT), undefined)
}

export function CheckValidDate(YYYYMMDD: string): boolean {
    const check = GetDateFromStr(YYYYMMDD);
    return check !== undefined && check > 0;
}