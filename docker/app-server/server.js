import express from 'express';
import os from 'os';
import osu from 'os-utils';

const app = express();
const port = process.env.PORT || 3000;

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.get('/api/status', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

app.get('/api/metrics', async (req, res) => {
  try {
    const hostname = os.hostname();
    const platform = os.platform();
    const arch = os.arch();
    const release = os.release();
    const cpus = os.cpus();
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const loadAvg = os.loadavg();

    const cpuPercent = await new Promise((resolve, reject) => {
      let settled = false;
      const t = setTimeout(() => {
        if (settled) return;
        settled = true;
        // Timeout: return null to avoid hanging the request
        resolve(null);
      }, 1500);
      try {
        osu.cpuUsage((val) => {
          if (settled) return;
          settled = true;
          clearTimeout(t);
          resolve(typeof val === 'number' ? val : null);
        });
      } catch (e) {
        if (settled) return;
        settled = true;
        clearTimeout(t);
        reject(e);
      }
    }).catch(() => null);

    const metrics = {
      server: 'app-server',
      hostname,
      os: { platform, arch, release },
      cpu: {
        cores: cpus.length,
        model: cpus[0]?.model,
        speedMHz: cpus[0]?.speed,
        usagePercent: cpuPercent == null ? null : Math.round(cpuPercent * 10000) / 100,
        loadAverage: { '1m': loadAvg[0], '5m': loadAvg[1], '15m': loadAvg[2] }
      },
      memory: {
        totalBytes: totalMem,
        freeBytes: freeMem,
        usedBytes: totalMem - freeMem,
        usedPercent: Math.round(((totalMem - freeMem) / totalMem) * 10000) / 100
      },
      network: {
        interfaces: Object.fromEntries(Object.entries(os.networkInterfaces() || {}))
      },
      timestamp: new Date().toISOString()
    };
    res.json(metrics);
  } catch (err) {
    res.status(500).json({ error: 'failed_to_collect_metrics', message: String(err) });
  }
});

app.listen(port, () => {
  console.log(`App server listening on port ${port}`);
});
