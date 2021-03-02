"""00011 - Base

Revision ID: 100013
Revises: 100010
Create Date: 2020-09-08

"""

# revision identifiers, used by Alembic.
revision = '100014'
down_revision = '100013'

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import mysql


def upgrade():
	### commands auto generated by Alembic - please adjust! ###

	op.create_table('mp_provision_ui_config',
					sa.Column('rid', sa.BigInteger(), nullable=False, autoincrement=True),
					sa.Column('configName', sa.String(length=255), nullable=False),
					sa.Column('config', mysql.TEXT(), nullable=False),
					sa.Column('active', sa.Integer(), server_default='1', nullable=True),
					sa.Column('scope', sa.Integer(), server_default='0', nullable=True),
					sa.Column('mdate', sa.DateTime(), server_default='1970-01-01 00:00:00', nullable=True),
					sa.PrimaryKeyConstraint('rid')
					)

	### end Alembic commands ###


def downgrade():
	### commands auto generated by Alembic - please adjust! ###
	op.drop_table('mp_provision_ui_config')

	### end Alembic commands ###