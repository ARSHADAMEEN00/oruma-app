import mongoose, { Schema, Document } from 'mongoose';
import { User } from './index';

export interface UserDocument extends User, Document { }

const UserSchema = new Schema<UserDocument>(
    {
        email: { type: String, required: true, unique: true, trim: true, lowercase: true },
        password: { type: String, required: true },
        name: { type: String, required: true, trim: true },
        role: { type: String, enum: ['admin', 'user'], default: 'user' },
    },
    { timestamps: true }
);

export const UserModel =
    mongoose.models.User ||
    mongoose.model<UserDocument>('User', UserSchema);
