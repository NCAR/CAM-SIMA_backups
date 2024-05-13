#!/usr/bin/env python3

"""
Combine CAM's namelist_definition and namelist_defaults into unified CIME format
"""

# Python library imports
import xml.etree.ElementTree as ET
import os
import os.path
import re
import sys

_HEADER = ['<?xml version="1.0"?>',
           '<?xml-stylesheet type="text/xsl" href="namelist_definition.xsl"?>']

_orphan_nlvars = ['ndep_list', 'subcol_vamp_ctyp', 'subcol_vamp_nsubc',
                  'subcol_vamp_otyp', 'scm_clubb_iop_name', 'drydep_list',
                  'drydep_method', 'lght_landmask_file', 'carma_fields']

_bogus_groups = ['configurable_model_flags', 'initvars', 'initspread',
                 'statsnl', 'micro_m2005', 'bncuiodsbjcb', 'stats_setting',
                 'clubb_silhs', 'sgs_tke', 'docn_nml', 'megan_emis_nl',
                 'seq_timemgr_inparm', 'seq_infodata_inparm', 'papi_inparm',
                 'seq_cplflds_inparm', 'seq_cplflds_userspec', 'prof_inparm',
                 'cime_driver_inst', 'shr_strdata_nml', 'cime_pes',
                 'seq_flux_mct_inparm', 'dom_inparm', 'fire_emis_nl',
                 'pio_default_inparm', 'camexp']

_true_re = re.compile(r"(?i)(true$)|([.]true[.]$)|('[.]true[.]'$)")
_false_re = re.compile(r"(?i)('[.]false[.]'$)|(['.]false[.']$)|(false$)")
_dq_string = r'("[^"]*"$)'
_string_re = re.compile(r"('[^']*'$)|" + _dq_string)

def strip_quotes(string):
    """Strip quotes aroud <string>, if present"""
    tstr = string.strip()
    if (tstr[0] == '"') and (tstr[-1] == '"'):
        tstr = tstr[1:-1]
    elif (tstr[0] == "'") and (tstr[-1] == "'"):
        tstr = tstr[1:-1]
    # End if
    return tstr

def is_goodnumber(string, type_):
    """Return True and the value if <string> represents a valid object
    of numerical type, <type_>.
    Numerical types are 'integer' and 'real'.
    Otherwise, return False and None"""
    retval = False
    retnum = None
    if type_[0:7] == 'integer':
        try:
            retnum = int(string)
            retval = True
        except ValueError as ve:
            pass # We already have correct bad return values
        # End try
    elif type_[0:4] == 'real':
        if string.rstrip()[-3:] == '_r8':
            string = string[0:-3]
        # End if
        try:
            retnum = float(string)
            retval = True
        except ValueError as ve:
            pass # We already have correct bad return values
        # End try
    # End if
    return retval, retnum

def is_goodval(string, type_):
    """Return True and the value if <string> represents a valid object
    of type, <type_>.
    Otherwise, return False and None"""
    retval, retnum = is_goodnumber(string, type_)
    if (not retval) and (type_[0:5] == 'char*'):
        string = string.strip()
        if _string_re.match(string):
            retnum = strip_quotes(string)
            retval = True
        # End if
    # End if
    return retval, retnum

# namelist_definition_old.xml is a copy of namelist_definition.xml
with open("namelist_definition_old.xml", 'r', encoding='utf-8') as fd:
    namelist_definition_tree = ET.parse(fd)
    namelist_definition_root = namelist_definition_tree.getroot()
# End with
_all_definitions = set() # All namelist variables in use
# namelist_defaults_cam.xml is a copy with '%' ==> '__' (% is invalid in name)
with open("namelist_defaults_cam.xml", 'r', encoding='utf-8') as fd:
    namelist_defaults_tree = ET.parse(fd)
    namelist_defaults_root = namelist_defaults_tree.getroot()
# End with
# Define new tree
newdef = ET.Element("entry_id")
newdef.set("version", "2.0")
# Translate all entries
for entry in namelist_definition_root:
    eid = entry.get("id")
    gid = entry.get("group")
    if (gid in _bogus_groups) or (eid in _orphan_nlvars):
        continue # We do not want this entry
    # End if
    if eid in _all_definitions:
        raise ValueError("Duplicate namelist definition, '{}'".format(eid))
    # end if
    _all_definitions.add(eid)
    type_ = entry.get("type")
    new_entry = ET.SubElement(newdef, "entry")
    new_entry.set("id", eid)
    new_type = ET.SubElement(new_entry, "type")
    new_type.text = type_
    new_category = ET.SubElement(new_entry, "category")
    new_category.text = entry.get("category")
    new_group = ET.SubElement(new_entry, "group")
    new_group.text = gid
    # Format the description and pull out any default value
    desc = ""
    desc_defval = None
    entry_lines = entry.text.split('\n')
    if len(entry_lines[-1].strip()) == 0:
        entry_lines = entry_lines[0:-1]
    # End if
    indent = 0
    line = entry_lines[0] or entry_lines[1]
    while (len(line) > indent) and (line[indent] == ' '):
        indent += 1
    # End if
    indent = ' '*max(6 - indent, 0)
    for line in entry_lines:
        lline = line.strip()
        add_line = True
        desc_default_line = ''
        if lline[0:8].lower() == 'default:':
            # Try to pick off some easy or bad default values
            isgood, goodval = is_goodval(lline[8:], type_)
            if isgood:
                desc_defval = goodval
                add_line = False
            elif 'set by build-namelist' in lline:
                desc_default_line = lline.replace('set by build-namelist',
                                                  'UNKNOWN')
                add_line = False
            elif 'Set by build-namelist' in lline:
                desc_default_line = lline.replace('Set by build-namelist',
                                                  'UNKNOWN')
                add_line = False
            elif 'set by configure' in lline.lower():
                line = lline.replace('set by configure',
                                     'set by configuration')
            elif (_true_re.match(lline[9:].lstrip()) and
                  (type_[0:7] == 'logical')):
                desc_defval = '.true.'
                add_line = False
            elif (_false_re.match(lline[9:].lstrip()) and
                  (type_[0:7] == 'logical')):
                desc_defval = '.false.'
                add_line = False
            # End if
        elif lline.strip() == 'Set by build-namelist.':
            add_line = False
        # End if
        if add_line:
            desc += indent + line + '\n'
        # End if
    # End if
    # Try to find default values for this entry
    values = list()
    testid = eid.replace('%', '__')
    found_defval = False
    default_value = None
    for defval in namelist_defaults_root:
        if defval.tag == testid:
            values.append(defval)
            if not defval.attrib:
                # We have a default value, cancel Default statement:
                desc_default_line = ''
                found_defval = True
                default_value = defval.text.strip()
            # End if
        # End if
    # End for
    if (not found_defval) and (desc_defval is not None):
        default_value = str(desc_defval)
    # End if
    # Check and output valid_values
    vv = entry.get("valid_values")
    if vv:
        if type_[0:7] == 'logical':
            emsg = 'Logical namelist item, {}, cannot have a valid_values entry'
            raise ValueError(emsg.format(eid))
        # End if
        valid_vals = [x.strip() for x in vv.split(',')]
        # Are the valid values themselves valid?
        for valid_val in valid_vals:
            retval, retnum = is_goodnumber(valid_val, type_)
            if (not retval) and (type_[0:5] != 'char*'):
                emsg = '{} is an invalid value for {} namelist item, {}'
                raise ValueError(emsg.format(valid_val, type_, eid))
            # End if
        # End for
        # Is the default value valid?
        if found_defval or (desc_defval is not None):
            if default_value not in valid_vals:
                emsg = 'Default Value Error for {}: {} not in {}'
                raise ValueError(emsg.format(eid, default_value, vv))
            # End if
        # Create the valid_values element
        new_valid_values = ET.SubElement(new_entry, "valid_values")
        new_valid_values.text = vv
    # End if
    # Output the description
    new_desc = ET.SubElement(new_entry, "desc")
    if desc_default_line:
        desc += indent + desc_default_line + '\n'
    # End if
    new_desc.text = desc
    if values or (desc_defval is not None):
        values_element = ET.SubElement(new_entry, "values")
        # Do we need to add any attributes such as match="first"?
        for value in values:
            newval = ET.SubElement(values_element, "value")
            for attrib in value.attrib:
                newval.set(attrib, value.get(attrib).strip())
            # End for
            newval.text = value.text.strip()
        # End for
        if (not found_defval) and (desc_defval is not None):
            # Add a default value scraped from the description
            newval = ET.SubElement(values_element, "value")
            newval.text = str(desc_defval)
        # End if
    # End if
# End for
# Check for bad defaults
_bad_entries = set()
for entry in namelist_defaults_root:
    tag = entry.tag.replace('__', '%')
    if tag not in _all_definitions:
        _bad_entries.add(tag)
    # end if
# end for
if _bad_entries:
    berr = "Bad namelist default entries:\n{}"
    raise ValueError(berr.format('\n'.join(list(_bad_entries))))
# end if
# Write tree
newdef_tree = ET.ElementTree(newdef)
newdef_tree.write("namelist_definition_1L.xml")
# Gather comments from original namelist file
comments = {}
with open("namelist_definition_old.xml", 'r', encoding='utf-8') as fd:
    comment = ""
    incomment = False
    for line in fd:
        lline = line.lstrip()
        if lline[0:4] == '<!--':
            incomment = True
        # End if
        isentry = lline[0:6] == '<entry'
        if incomment and (not isentry):
            comment += line
        # End if
        if comment and isentry:
            id = lline.split(' ')[1].split('=')[1].strip()
            comments[id] = comment
            comment = ""
            incomment = False
        # End if
    # End for
# End with
# Reformat file
with open("namelist_definition_1L.xml", 'r', encoding='utf-8') as infile:
        input = infile.readlines()
# End with
with open("namelist_definition_cam.xml", 'w', encoding='utf-8') as outfile:
    indent = 0
    for line in _HEADER:
        outfile.write('{}\n\n'.format(line))
    # End if
    for line in input:
        sline = line.strip()
        if sline and ((sline[0] == '<') or ('><' in sline)):
            inlines = sline.split('><')
            begtag = inlines[0][0] == '<'
            if begtag:
                inlines[0] = inlines[0].lstrip('<')
            # End if
            endtag = inlines[-1][-1] == '>'
            if endtag:
                inlines[-1] = inlines[-1].rstrip('>')
            # End if
            lineno = 0
            lastline = len(inlines)
            for inline in inlines:
                lineno += 1
                if (inline[0:6] == '/entry') or (inline[0:7] == '/values'):
                    indent -= 2
                # End if
                isentry = inline[0:5] == 'entry'
                if isentry:
                    id = inline.split(' ')[1].split('=')[1].strip()
                    if id in comments:
                        outfile.write('\n{}'.format(comments[id]))
                    # End if
                # End if
                if (lineno == 1) and (not begtag):
                    bb = ''
                else:
                    bb = '<'
                # End if
                if (lineno == lastline) and (not endtag):
                    eb = ''
                else:
                    eb = '>'
                # End if
                outfile.write('{}{}{}{}\n'.format(' '*indent, bb, inline, eb))
                if isentry or (inline[0:6] == 'values'):
                    indent += 2
                # End if
            # End for
        else:
            outfile.write(line)
        # End if
    # End for
# End with
os.remove("namelist_definition_1L.xml")
