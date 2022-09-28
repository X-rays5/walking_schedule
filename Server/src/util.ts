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
    console.error(error);
}

export function ResponseSuccess(res: Response, data: Object) {
    res.status(200);
    res.json({
        success: true,
        data: data
    });
}

export function GetDateFromStr(YYYYMMDD: string): number {
    return parseInt(date.format(new Date(YYYYMMDD), DATABASE_DATE_FORMAT))
}

export function CheckValidDate(YYYYMMDD: string): boolean {
    const check = GetDateFromStr(YYYYMMDD);
    return check != undefined && check > 0;
}