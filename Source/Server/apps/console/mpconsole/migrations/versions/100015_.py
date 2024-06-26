"""00015 - Base

Revision ID: 100015
Revises: 100014
Create Date: 2020-09-08

"""

# revision identifiers, used by Alembic.
revision = '100015'
down_revision = '100014'

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import mysql


def upgrade():
	### commands auto generated by Alembic - please adjust! ###

	op.create_table('mp_provision_criteria',
		sa.Column('rid', sa.BigInteger(), nullable=False, autoincrement=True),
		sa.Column('type', sa.String(length=50), nullable=False),
		sa.Column('type_data', mysql.TEXT(), nullable=False),
		sa.Column('order', sa.Integer(), server_default='1', nullable=True),
		sa.Column('active', sa.Integer(), server_default='0', nullable=True),
		sa.Column('scope', sa.String(length=50), server_default='prod', nullable=False),
		sa.Column('mdate', sa.DateTime(), server_default='1970-01-01 00:00:00', nullable=True),
		sa.PrimaryKeyConstraint('rid')
	)

	### end Alembic commands ###


def downgrade():
	### commands auto generated by Alembic - please adjust! ###
	op.drop_table('mp_provision_criteria')

	### end Alembic commands ###