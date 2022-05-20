function model_to_sbml!(doc::VPtr, mdl::Model)::VPtr
    # Create the model pinter
    model = ccall(sbml(:SBMLDocument_createModel), VPtr, (VPtr,), doc)

    # Add units
    for (name, units) in mdl.units
        res = ccall(sbml(:Model_addUnitDefinition), Cint, (VPtr, VPtr),
                    model, unit_definition(name, units))
        !iszero(res) && @warn "Failed to add unit \"$(name)\": $(OPERATION_RETURN_VALUES[res])"
    end

    # Add compartments
    for (id, compartment) in mdl.compartments
        compartment_t = ccall(sbml(:Compartment_create), VPtr, (Cuint, Cuint), 3, 2)
        ccall(sbml(:Compartment_setId), Cint, (VPtr, Cstring), compartment_t, id)
        isnothing(compartment.name) || ccall(sbml(:Compartment_setName), Cint, (VPtr, Cstring), compartment_t, compartment.name)
        isnothing(compartment.constant) || ccall(sbml(:Compartment_setConstant), Cint, (VPtr, Cint), compartment_t, Cint(compartment.constant))
        isnothing(compartment.spatial_dimensions) || ccall(sbml(:Compartment_setSpatialDimensions), Cint, (VPtr, Cuint), compartment_t, Cuint(compartment.spatial_dimensions))
        isnothing(compartment.size) || ccall(sbml(:Compartment_setSize), Cint, (VPtr, Cdouble), compartment_t, Cdouble(compartment.size))
        isnothing(compartment.units) || ccall(sbml(:Compartment_setUnits), Cint, (VPtr, Cstring), compartment_t, compartment.units)
        isnothing(compartment.notes) || ccall(sbml(:SBase_setNotesString), Cint, (VPtr, Cstring), compartment_t, compartment.notes)
        isnothing(compartment.annotation) || ccall(sbml(:SBase_setAnnotationString), Cint, (VPtr, Cstring), compartment_t, compartment.annotation)
        res = ccall(sbml(:Model_addCompartment), Cint, (VPtr, VPtr), model, compartment_t)
        !iszero(res) && @warn "Failed to add compartment \"$(id)\": $(OPERATION_RETURN_VALUES[res])"
    end

    # Add gene products
    for (id, gene_product) in mdl.gene_products
        geneproduct_t = ccall(sbml(:GeneProduct_create), VPtr, (Cuint, Cuint, Cuint), 3, 2, 2) # TODO: check what the PkgVersion should be
        ccall(sbml(:GeneProduct_setId), Cint, (VPtr, Cstring), geneproduct_t, id)
        isnothing(gene_product.name) || ccall(sbml(:GeneProduct_setName), Cint, (VPtr, Cstring), geneproduct_t, gene_product.name)
        isnothing(gene_product.label) || ccall(sbml(:GeneProduct_setLabel), Cint, (VPtr, Cstring), geneproduct_t, gene_product.label)
        isnothing(gene_product.notes) || ccall(sbml(:SBase_setNotesString), Cint, (VPtr, Cstring), geneproduct_t, gene_product.notes)
        isnothing(gene_product.annotation) || ccall(sbml(:SBase_setAnnotationString), Cint, (VPtr, Cstring), geneproduct_t, gene_product.annotation)
        # TODO: add the gene product to the FBC package
        # res = ccall(sbml(:FbcModelPlugin_addGeneProduct), Cint, (VPtr, VPtr), model_fbc, geneproduct_t)
        # !iszero(res) && @warn "Failed to add gene product \"$(id)\": $(OPERATION_RETURN_VALUES[res])"
    end

    # Add species
    for (id, species) in mdl.species
        species_t = ccall(sbml(:Species_create), VPtr, (Cuint, Cuint), 3, 2)
        ccall(sbml(:Species_setId), Cint, (VPtr, Cstring), species_t, id)
        isnothing(species.name) || ccall(sbml(:Species_setName), Cint, (VPtr, Cstring), species_t, species.name)
        isnothing(species.compartment) || ccall(sbml(:Species_setCompartment), Cint, (VPtr, Cstring), species_t, species.compartment)
        isnothing(species.boundary_condition) || ccall(sbml(:Species_setBoundaryCondition), Cint, (VPtr, Cint), species_t, species.boundary_condition)
        # isnothing(species.formula) || ccall(sbml(:Species_setFormula), Cint, (VPtr, Cstring), species_t, species.compartment)
        isnothing(species.charge) || ccall(sbml(:Species_setCharge), Cint, (VPtr, Cint), species_t, species.charge)
        isnothing(species.initial_amount) || ccall(sbml(:Species_setInitialAmount), Cint, (VPtr, Cdouble), species_t, species.initial_amount)
        isnothing(species.initial_concentration) || ccall(sbml(:Species_setInitialConcentration), Cint, (VPtr, Cdouble), species_t, species.initial_concentration)
        isnothing(species.substance_units) || ccall(sbml(:Species_setSubstanceUnits), Cint, (VPtr, Cstring), species_t, species.substance_units)
        isnothing(species.only_substance_units) || ccall(sbml(:Species_setHasOnlySubstanceUnits), Cint, (VPtr, Cint), species_t, species.only_substance_units)
        isnothing(species.constant) || ccall(sbml(:Species_setConstant), Cint, (VPtr, Cint), species_t, species.constant)
        isnothing(species.metaid) || ccall(sbml(:SBase_setMetaId), Cint, (VPtr, Cstring), species_t, species.metaid)
        isnothing(species.notes) || ccall(sbml(:SBase_setNotesString), Cint, (VPtr, Cstring), species_t, species.notes)
        isnothing(species.annotation) || ccall(sbml(:SBase_setAnnotationString), Cint, (VPtr, Cstring), species_t, species.annotation)
        res = ccall(sbml(:Model_addSpecies), Cint, (VPtr, VPtr), model, species_t)
        !iszero(res) && @warn "Failed to add species \"$(id)\": $(OPERATION_RETURN_VALUES[res])"
    end

    # We can finally return the model
    return model
end

function writeSBML(mdl::Model, fn::String)
    doc = ccall(sbml(:SBMLDocument_createWithLevelAndVersion), VPtr, (Cuint, Cuint), 3, 2)
    model = try
        model_to_sbml!(doc, mdl)
        res = ccall(sbml(:writeSBML), Cint, (VPtr, Cstring), doc, fn)
        res == 1 || error("Writing the SBML failed")
    finally
        ccall(sbml(:SBMLDocument_free), Cvoid, (VPtr,), doc)
    end
    return nothing
end

function writeSBML(mdl::Model)::String
    doc = ccall(sbml(:SBMLDocument_createWithLevelAndVersion), VPtr, (Cuint, Cuint), 3, 2)
    str = try
        model_to_sbml!(doc, mdl)
        unsafe_string(ccall(sbml(:writeSBMLToString), Cstring, (VPtr,), doc))
    finally
        ccall(sbml(:SBMLDocument_free), Cvoid, (VPtr,), doc)
    end
    return str
end
