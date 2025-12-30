import mongoose from 'mongoose';

export async function connectDb(uri: string) {
  if (!uri) {
    throw new Error('MONGO_URI is required to connect to MongoDB');
  }

  // Use Mongoose to manage the connection pool.
  await mongoose.connect(uri);
  console.log('✅ Connected to MongoDB');
}

