import { Router, Request, Response } from 'express';
import { patientService } from '../services/patientService';
import { Patient } from '../models';

const router = Router();

// GET all patients
router.get('/', async (req: Request, res: Response) => {
  try {
    const patients = await patientService.getAll();
    res.json(patients);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch patients' });
  }
});

// GET patient by ID
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const patient = await patientService.getById(req.params.id);
    if (!patient) {
      return res.status(404).json({ error: 'Patient not found' });
    }
    res.json(patient);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch patient' });
  }
});

// POST create new patient
router.post('/', async (req: Request, res: Response) => {
  try {
    const patientData: Patient = req.body;

    // Basic validation
    if (!patientData.name || !patientData.gender || !patientData.village) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if ((req as any).user) {
      patientData.createdBy = (req as any).user._id;
    }

    const patient = await patientService.create(patientData);
    res.status(201).json(patient);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create patient' });
  }
});

// PUT update patient
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const updates: Partial<Patient> = req.body;
    const patient = await patientService.update(req.params.id, updates);

    if (!patient) {
      return res.status(404).json({ error: 'Patient not found' });
    }

    res.json(patient);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update patient' });
  }
});

// DELETE patient
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const deleted = await patientService.delete(req.params.id);

    if (!deleted) {
      return res.status(404).json({ error: 'Patient not found' });
    }

    res.json({ message: 'Patient deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete patient' });
  }
});

export default router;

