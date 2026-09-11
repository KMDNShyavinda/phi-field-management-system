import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

const PHI_LOGO_COLOR = [22, 101, 52]; // dark green
const HEADER_BG = [240, 253, 244];

function addReportHeader(doc: jsPDF, title: string, subtitle: string) {
  // Header bar
  doc.setFillColor(...(PHI_LOGO_COLOR as [number, number, number]));
  doc.rect(0, 0, 210, 22, 'F');

  // Title
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.text('PHI Field Management System', 14, 10);

  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  doc.text('Ministry of Health - Sri Lanka', 14, 16);

  // Report title box
  doc.setFillColor(...(HEADER_BG as [number, number, number]));
  doc.rect(0, 22, 210, 14, 'F');
  doc.setTextColor(22, 101, 52);
  doc.setFontSize(13);
  doc.setFont('helvetica', 'bold');
  doc.text(title, 14, 31);

  doc.setTextColor(100, 100, 100);
  doc.setFontSize(8);
  doc.setFont('helvetica', 'normal');
  doc.text(subtitle, 14, 35);

  // Date on right
  const now = new Date().toLocaleString('en-GB');
  doc.text(`Generated: ${now}`, 196, 35, { align: 'right' });

  doc.setTextColor(0, 0, 0);
}

function addFooter(doc: jsPDF) {
  const pageCount = (doc as any).internal.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.setFillColor(22, 101, 52);
    doc.rect(0, 285, 210, 12, 'F');
    doc.setTextColor(255, 255, 255);
    doc.setFontSize(7);
    doc.text('PHI Field Management System | Ministry of Health, Sri Lanka | CONFIDENTIAL', 14, 292);
    doc.text(`Page ${i} of ${pageCount}`, 196, 292, { align: 'right' });
  }
}

export function generateInspectionsPDF(inspections: any[]) {
  const doc = new jsPDF();
  addReportHeader(
    doc,
    'Field Inspections Report',
    `Total Records: ${inspections.length}`
  );

  autoTable(doc, {
    startY: 40,
    head: [['#', 'Premise', 'PHI Officer', 'Date', 'Compliance Score']],
    body: inspections.map((i, idx) => [
      idx + 1,
      i.premise_name,
      i.officer_name,
      new Date(i.started_at).toLocaleDateString('en-GB'),
      i.compliance_score !== null ? `${i.compliance_score}%` : 'N/A',
    ]),
    headStyles: {
      fillColor: PHI_LOGO_COLOR as [number, number, number],
      textColor: [255, 255, 255],
      fontStyle: 'bold',
    },
    alternateRowStyles: { fillColor: [245, 245, 245] },
    styles: { fontSize: 9, cellPadding: 3 },
    columnStyles: {
      0: { cellWidth: 10 },
      4: { halign: 'center' },
    },
  });

  addFooter(doc);
  doc.save(`PHI_Inspections_Report_${new Date().toISOString().slice(0, 10)}.pdf`);
}

export function generateComplaintsPDF(complaints: any[]) {
  const doc = new jsPDF();
  addReportHeader(
    doc,
    'Complaints Management Report',
    `Total Records: ${complaints.length}`
  );

  // Summary boxes
  const pending = complaints.filter(c => c.status === 'pending').length;
  const resolved = complaints.filter(c => c.status === 'resolved').length;
  const emergency = complaints.filter(c => c.priority === 'emergency').length;

  doc.setFontSize(9);
  doc.setTextColor(0, 0, 0);

  const summaryData = [
    { label: 'Total', value: complaints.length, color: [59, 130, 246] },
    { label: 'Pending', value: pending, color: [234, 179, 8] },
    { label: 'Resolved', value: resolved, color: [22, 163, 74] },
    { label: 'Emergency', value: emergency, color: [220, 38, 38] },
  ];

  summaryData.forEach((s, i) => {
    const x = 14 + i * 46;
    doc.setFillColor(...(s.color as [number, number, number]));
    doc.roundedRect(x, 41, 42, 14, 2, 2, 'F');
    doc.setTextColor(255, 255, 255);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(12);
    doc.text(String(s.value), x + 21, 50, { align: 'center' });
    doc.setFontSize(7);
    doc.setFont('helvetica', 'normal');
    doc.text(s.label, x + 21, 54, { align: 'center' });
  });

  doc.setTextColor(0, 0, 0);

  autoTable(doc, {
    startY: 60,
    head: [['#', 'Tracking No', 'Title', 'Priority', 'Status', 'Received Date']],
    body: complaints.map((c, idx) => [
      idx + 1,
      c.tracking_no,
      c.title,
      c.priority.toUpperCase(),
      c.status.toUpperCase(),
      new Date(c.received_date).toLocaleDateString('en-GB'),
    ]),
    headStyles: {
      fillColor: PHI_LOGO_COLOR as [number, number, number],
      textColor: [255, 255, 255],
      fontStyle: 'bold',
    },
    alternateRowStyles: { fillColor: [245, 245, 245] },
    styles: { fontSize: 9, cellPadding: 3 },
    columnStyles: {
      0: { cellWidth: 10 },
      3: {
        halign: 'center',
      },
      4: { halign: 'center' },
    },
    didDrawCell: (data) => {
      if (data.column.index === 3 && data.section === 'body') {
        const val = data.cell.text[0];
        if (val === 'EMERGENCY') {
          doc.setFillColor(220, 38, 38);
        } else if (val === 'HIGH') {
          doc.setFillColor(234, 88, 12);
        } else {
          doc.setFillColor(22, 163, 74);
        }
      }
    },
  });

  addFooter(doc);
  doc.save(`PHI_Complaints_Report_${new Date().toISOString().slice(0, 10)}.pdf`);
}

export function generateOfficersPDF(officers: any[]) {
  const doc = new jsPDF();
  addReportHeader(
    doc,
    'PHI Officers Report',
    `Total Officers: ${officers.length}`
  );

  autoTable(doc, {
    startY: 40,
    head: [['#', 'Full Name', 'Email', 'MOH Area', 'Status']],
    body: officers.map((o, idx) => [
      idx + 1,
      o.full_name,
      o.email,
      o.moh_area || 'Not assigned',
      o.is_active ? 'ACTIVE' : 'INACTIVE',
    ]),
    headStyles: {
      fillColor: PHI_LOGO_COLOR as [number, number, number],
      textColor: [255, 255, 255],
      fontStyle: 'bold',
    },
    alternateRowStyles: { fillColor: [245, 245, 245] },
    styles: { fontSize: 9, cellPadding: 3 },
    columnStyles: {
      0: { cellWidth: 10 },
      4: { halign: 'center' },
    },
  });

  addFooter(doc);
  doc.save(`PHI_Officers_Report_${new Date().toISOString().slice(0, 10)}.pdf`);
}
