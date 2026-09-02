"""initial schema

Revision ID: 001
Revises:
Create Date: 2026-09-01
"""

from alembic import op
import sqlalchemy as sa

revision = "001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("full_name", sa.String(255), nullable=False),
        sa.Column("role", sa.String(32), nullable=False),
        sa.Column("moh_area", sa.String(128), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_table(
        "premises",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("address", sa.String(512), nullable=False),
        sa.Column("owner_name", sa.String(255), nullable=False),
        sa.Column("owner_phone", sa.String(64), nullable=True),
        sa.Column("qr_code", sa.String(128), nullable=False, unique=True),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.Column("risk", sa.String(32), nullable=False),
        sa.Column("moh_area", sa.String(128), nullable=False),
        sa.Column("compliance_score", sa.Integer(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_premises_moh_area", "premises", ["moh_area"])
    op.create_table(
        "checklist_templates",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_table(
        "checklist_items",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("template_id", sa.Uuid(), sa.ForeignKey("checklist_templates.id"), nullable=False),
        sa.Column("code", sa.String(64), nullable=False),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.Column("legal_hint", sa.Text(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_table(
        "scheduled_visits",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("premise_id", sa.Uuid(), sa.ForeignKey("premises.id"), nullable=False),
        sa.Column("officer_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("visit_date", sa.Date(), nullable=False),
        sa.Column("reason", sa.String(64), nullable=False),
        sa.Column("status", sa.String(32), nullable=False),
        sa.Column("inspection_id", sa.Uuid(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_table(
        "inspections",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("premise_id", sa.Uuid(), sa.ForeignKey("premises.id"), nullable=False),
        sa.Column("officer_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("template_id", sa.Uuid(), sa.ForeignKey("checklist_templates.id"), nullable=False),
        sa.Column("status", sa.String(32), nullable=False),
        sa.Column("started_at", sa.DateTime(), nullable=False),
        sa.Column("completed_at", sa.DateTime(), nullable=True),
        sa.Column("start_lat", sa.Float(), nullable=True),
        sa.Column("start_lng", sa.Float(), nullable=True),
        sa.Column("submit_lat", sa.Float(), nullable=True),
        sa.Column("submit_lng", sa.Float(), nullable=True),
        sa.Column("gps_status", sa.String(32), nullable=False),
        sa.Column("follow_up_date", sa.Date(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("pdf_path", sa.String(512), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_table(
        "inspection_answers",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("inspection_id", sa.Uuid(), sa.ForeignKey("inspections.id"), nullable=False),
        sa.Column("item_id", sa.Uuid(), sa.ForeignKey("checklist_items.id"), nullable=False),
        sa.Column("result", sa.String(16), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("inspection_id", "item_id", name="uq_answer_item"),
    )
    op.create_table(
        "evidence_photos",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("inspection_id", sa.Uuid(), sa.ForeignKey("inspections.id"), nullable=False),
        sa.Column("item_id", sa.Uuid(), sa.ForeignKey("checklist_items.id"), nullable=True),
        sa.Column("sha256", sa.String(64), nullable=False),
        sa.Column("captured_at", sa.DateTime(), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.Column("storage_path", sa.String(512), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_table(
        "violations",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("inspection_id", sa.Uuid(), sa.ForeignKey("inspections.id"), nullable=False),
        sa.Column("item_id", sa.Uuid(), sa.ForeignKey("checklist_items.id"), nullable=False),
        sa.Column("notice_type", sa.String(64), nullable=False),
        sa.Column("legal_provision", sa.Text(), nullable=False),
        sa.Column("deadline", sa.Date(), nullable=False),
        sa.Column("accepted", sa.Boolean(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_table(
        "signatures",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("inspection_id", sa.Uuid(), sa.ForeignKey("inspections.id"), nullable=False),
        sa.Column("signer_role", sa.String(32), nullable=False),
        sa.Column("signer_name", sa.String(255), nullable=False),
        sa.Column("image_path", sa.String(512), nullable=False),
        sa.Column("image_b64", sa.Text(), nullable=True),
        sa.Column("signed_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("inspection_id", "signer_role", name="uq_signature_role"),
    )


def downgrade() -> None:
    op.drop_table("signatures")
    op.drop_table("violations")
    op.drop_table("evidence_photos")
    op.drop_table("inspection_answers")
    op.drop_table("inspections")
    op.drop_table("scheduled_visits")
    op.drop_table("checklist_items")
    op.drop_table("checklist_templates")
    op.drop_table("premises")
    op.drop_table("users")
