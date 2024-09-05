
import fs from 'fs';
import { PROOF_PATH } from './config';

export const loadProof = () => JSON.parse(fs.readFileSync(PROOF_PATH, 'utf-8'));