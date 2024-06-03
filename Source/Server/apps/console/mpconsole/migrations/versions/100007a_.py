"""0007a - Base

Revision ID: 100007a
Revises: 100007
Create Date: 2019-07-24

"""

# revision identifiers, used by Alembic.
revision = '100007a'
down_revision = '100007'

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import mysql


def upgrade():
	### commands auto generated by Alembic - please adjust! ###

	### end Alembic commands ###
	u_qstr1="""
		CREATE PROCEDURE `AgentUpdateRID`( IN a_type VARCHAR(10) )
		BEGIN
		Select rid From mp_client_agents
						Where type = a_type
						AND active = '1'
						ORDER BY
						INET_ATON(SUBSTRING_INDEX(CONCAT(agent_ver,'.0.0.0.0.0'),'.',6)) DESC,
						INET_ATON(SUBSTRING_INDEX(CONCAT(build,'.0.0.0.0.0'),'.',6)) DESC;
		
		END;
	"""
	op.execute(u_qstr1)


def downgrade():
	### commands auto generated by Alembic - please adjust! ###

	### end Alembic commands ###
	d_qstr1 = "DROP PROCEDURE IF EXISTS `AgentUpdateRID`;"
	op.execute(d_qstr1)


