# Copyright 2021 David Justo, Shaoqing Yi, Nadia Polikarpova,
#     Lukas Stadler and, Arun Kumar
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file implements the Normalized Matrix interface in Python, which in turn
# delegates its operator semantics to MorpheusDSL. The implementation contains
# a large amount of boilerplate because it's meant to subclass NumPy matrices.
# In the mean, this didn't help us much as NumPy, in GraalPython, wasn't stable
# enough to run single-language experiements with it. Stil, for completeness' sake,
# we kept the boilerplate as we shifted towards running our Python implementation
# with R-based matrices as the "backend".

"""
Python package to support 'morpheus' rewrites of linear algebra operations
"""
import copy
import polyglot
import numpy as np
import numpy.core.numeric as N
from numpy.core.numeric import isscalar
from numpy.matrixlib.defmatrix import asmatrix, matrix

class NormalizedMatrix(matrix):

    """
    Array functions are created to follow numpy semantics.
    https://docs.scipy.org/doc/numpy-1.13.0/user/basics.subclassing.html
    
    1. Explicit constructor call
    2. View casting
    3. Creating from new template
    """
    def __array_prepare__(self, obj, context=None):
        pass

    def __array_wrap__(self, out_arr, context=None):
        pass

    def __array_finalize__(self, obj):
        pass

    _SUPPORTED_UFUNCS = {np.add: {1: "__add__", -1: "__radd__"},
                         np.subtract: {1: "__sub__", -1: "__rsub__"},
                         np.divide: {1: "__div__", -1: "__rdiv__"},
                         np.multiply: {1: "__mul__", -1: "__rmul__"},
                         np.power: {1: "__pow__", -1: "__rpow__"}}

    def __array_ufunc__(self, ufunc, method, *inputs, **kwargs):
        """
        Handle ufunc supported in numpy standard library.
        reference: https://docs.scipy.org/doc/numpy-1.13.0/reference/ufuncs.html

        :param ufunc: ufunc object
        :param method: type of method. In this class, only __call__ is handled
        :param inputs:
        :param kwargs:
        :return: Normalized matrix or matrix or ndarray or numeric
        """
        if ufunc in self._SUPPORTED_UFUNCS and len(inputs) == 2 and method == "__call__":
            order = isinstance(inputs[0], NormalizedMatrix) - isinstance(inputs[1], NormalizedMatrix)
            if order == 1:
                return getattr(inputs[0], self._SUPPORTED_UFUNCS[ufunc][order])(inputs[1], **kwargs)
            if order == -1:
                return getattr(inputs[1], self._SUPPORTED_UFUNCS[ufunc][order])(inputs[0], **kwargs)
            if order == 0 and ufunc is np.multiply:
                return inputs[0].__mul__(inputs[1], **kwargs)
        return NotImplemented

    def __repr__(self):
        return self.__str__()

    def __str__(self):
        return "NormalizedMatrix"

    def __getitem__(self, index):
        return NotImplementedError

    # Obtain a MorpheusDSL object to which to delegate our semantics
    def __getNormalizedTable(self, S, Ks, Rs, Sempty, avatar=None):
        normalizedTable = polyglot.eval(language="morpheusDSL",string="")
        if avatar is None:
            raise NotImplementedError
        normalizedTable.build(S, Ks, Rs, Sempty, avatar)
        return normalizedTable

    def __new__(cls, mat=None, S=None, Ks=None, Rs=None, is_transposed=False, foreign_backend=False, avatar=None):
        def curryed_avatar(fname, arg=None):
            if mat is None:
                raise NotImplementedError
            method = getattr(avatar, fname)
            if arg is None:
                return method(mat)
            return method(mat, arg)
         
        obj = N.ndarray.__new__(cls, None)
        obj.isMorpheus = False
        obj.avatar = avatar
        obj.mat = mat
        if mat is None:
            obj.isMorpheus = True
            obj.S = S
            obj.Ks = Ks
            obj.Rs = Rs
            obj.is_transposed = is_transposed
            obj.Sempty = False # NOTE: Sempty is never empty in our experiments
            obj.foreign_backend = foreign_backend

            if str(type(S)) == "<class 'foreign'>":
                obj.inner = obj.__getNormalizedTable(S, Ks, Rs, obj.Sempty, avatar)
            else:
                raise NotImplementedError
        else:
            obj.inner = curryed_avatar
        return obj

    def __array_finalize__(self, obj):
        if obj is None: return
        obj.inner = getattr(obj, 'inner')
        obj.isMorpheus = getattr(obj, 'isMorpheus')
        obj.avatar = getattr(obj, 'avatar')
        obj.mat = getattr(obj, 'mat')

    def dimm(self):
        return self.inner("dimmu")

    """ columnSum, rowSum, elementWiseSum """
    def sum(self, axis=None, dtype=None, out=None):
        raise NotImplementedError

    """ scalarExponentiation """
    def __pow__(self, other=2.71):
        newMat = self.inner("scalarMultiplication", other)
        return NormalizedMatrix(mat=newMat, avatar=self.avatar)

    def __ipow__(self, other=2.71):
        output = self.__pow__(other)
        self.normalizedTable = output.normalizedTable
        return self

    def __rpow__(self, other=2.71):
        return self.__pow__(other)

    """ matrixAddition and scalarAddition"""
    def __add__(self, other):
        if isscalar(other):
            if self.isMorpheus:
                raise NotImplementedError
            else:
                newMat = self.inner("scalarAddition", other)
                return NormalizedMatrix(mat=newMat, avatar=self.avatar)
        if self.isMorpheus:
            return NotImplementedError
        else:
            newMat = self.inner("matrixAddition", other.mat)
            return NormalizedMatrix(mat=newMat, avatar=self.avatar)
        return self.normalizedTable.matrixAddition(other).unwrap()

    def __iadd__(self, other):
        output =  self.__add__(other) 
        self.normalizedTable = output.normalizedTable
        return self
    def __radd__(self, other):
        return self.__add__(other)

    def __sub__(self, other):
        prepArg = other.__mul__(-1)
        return self.__add__(prepArg)

    def __isub__(self, other):
        return self.__iadd__(-other)
    def __rsub__(self, other):
        prepped = self.__mul__(-1)
        return self.__radd__(prepped)

    
    """ scalarMultiplication, crossProd, LMM and RMM """
    def __mul__(self, other):
        if isscalar(other):
            if self.isMorpheus:
                raise NotImplementedError
            else:
                newMat = self.inner("scalarMultiplication", other)
                return NormalizedMatrix(mat=newMat, avatar=self.avatar)
            return normMatrix

        elif isinstance(other, NormalizedMatrix):
            if self.isMorpheus:
                newMat = self.inner.leftMatrixMultiplication(other.mat)
                return NormalizedMatrix(mat=newMat, avatar=self.avatar)
            else:
                # Here the reason for the switch is that the names are backwards
                newMat = self.inner("rightMatrixMultiplication", other.mat)
                return NormalizedMatrix(mat=newMat, avatar=self.avatar)
        return NotImplemented

    def __rmul__(self, other):

        if isscalar(other):
            if self.isMorpheus:
                raise NotImplementedError
            else:
                newMat = self.inner("scalarMultiplication", other)
                return NormalizedMatrix(mat=newMat, avatar=self.avatar)

        if isinstance(other, NormalizedMatrix):
            if self.stamp == other.stamp and self.is_transposed ^ other.is_transposed:
                return self.normalizedTable.crossProduct().unwrap()
            else:
                raise NotImplementedError
        if isinstance(other, (N.ndarray, list,tuple)):
            raise NotImplementedError
        raise NotImplementedError

    def __imul__(self, other):
        if not isscalar(other):
            return NotImplemented

        self.normalizedTable = self.normalizedTable.scalarMultiplication(other)
        return self

    def __truediv__(self, other):
        newMat = other.inner("invert")
        preppedArg = NormalizedMatrix(mat=newMat, avatar=self.avatar)
        return self.__mul__(preppedArg)
    def __rtruediv__(self, other):
        return other.__truediv__(self)
    def __itruediv__(self, other):
        raise NotImplementedError

    @property
    def T(self):
        if self.isMorpheus:
            newMat = self.inner.transpose()
            normMat = NormalizedMatrix(S=self.S, Rs=self.Rs, Ks=self.Ks, avatar=self.avatar)
            normMat.inner = newMat
            return normMat
        else:
            newMat = self.inner("transpose")
            return NormalizedMatrix(mat=newMat, avatar=self.avatar)

