import { Router, Request, Response } from 'express';
import { equipmentService } from '../services/equipmentService';
import { Equipment } from '../models';

const router = Router();

// GET all equipment
router.get('/', async (req: Request, res: Response) => {
  try {
    const { status } = req.query;
    let equipment;

    if (status && typeof status === 'string') {
      equipment = await equipmentService.getByStatus(status);
    } else {
      equipment = await equipmentService.getAll();
    }

    res.json(equipment);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch equipment' });
  }
});

// GET available equipment count summary
router.get('/summary/available', async (req: Request, res: Response) => {
  try {
    const counts = await equipmentService.getAvailableCount();
    res.json(counts);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch equipment summary' });
  }
});

// GET equipment by ID
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const equipment = await equipmentService.getById(req.params.id);
    if (!equipment) {
      return res.status(404).json({ error: 'Equipment not found' });
    }
    res.json(equipment);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch equipment' });
  }
});

// GET equipment by unique ID
router.get('/unique/:uniqueId', async (req: Request, res: Response) => {
  try {
    const equipment = await equipmentService.getByUniqueId(req.params.uniqueId);
    if (!equipment) {
      return res.status(404).json({ error: 'Equipment not found' });
    }
    res.json(equipment);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch equipment' });
  }
});

// POST create new equipment (creates multiple if quantity > 1)
router.post('/', async (req: Request, res: Response) => {
  try {
    const equipmentData = req.body;

    // Basic validation
    if (!equipmentData.name || !equipmentData.phone) {
      return res.status(400).json({ error: 'Missing required fields (name, phone)' });
    }

    // Set default serialNo if not provided
    if (!equipmentData.serialNo) {
      equipmentData.serialNo = equipmentData.name
        .replace(/[^a-zA-Z]/g, '')
        .substring(0, 2)
        .toUpperCase() || 'EQ';
    }

    const equipment = await equipmentService.create(equipmentData);

    // Return the created equipment array
    res.status(201).json({
      message: `Successfully created ${equipment.length} equipment item(s)`,
      count: equipment.length,
      equipment: equipment,
    });
  } catch (error: any) {
    console.error('Error creating equipment:', error);
    res.status(500).json({ error: error.message || 'Failed to create equipment' });
  }
});

// PUT update equipment
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const updates: Partial<Equipment> = req.body;
    const equipment = await equipmentService.update(req.params.id, updates);

    if (!equipment) {
      return res.status(404).json({ error: 'Equipment not found' });
    }

    res.json(equipment);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update equipment' });
  }
});

// PATCH update equipment status
router.patch('/:id/status', async (req: Request, res: Response) => {
  try {
    const { status } = req.body;

    if (!['available', 'supplied', 'maintenance'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status. Must be: available, supplied, or maintenance' });
    }

    const equipment = await equipmentService.updateStatus(req.params.id, status);

    if (!equipment) {
      return res.status(404).json({ error: 'Equipment not found' });
    }

    res.json(equipment);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update equipment status' });
  }
});

// DELETE equipment
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const deleted = await equipmentService.delete(req.params.id);

    if (!deleted) {
      return res.status(404).json({ error: 'Equipment not found' });
    }

    res.json({ message: 'Equipment deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete equipment' });
  }
});

export default router;
